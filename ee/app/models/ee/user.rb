# frozen_string_literal: true

module EE
  # User EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `User` model
  module User
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include AuditorUserHelper

    DEFAULT_ROADMAP_LAYOUT = 'months'.freeze
    DEFAULT_GROUP_VIEW = 'details'.freeze
    MAX_USERNAME_SUGGESTION_ATTEMPTS = 15

    prepended do
      EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM = 1

      # We aren't using the `auditor?` method for the `if` condition here
      # because `auditor?` returns `false` when the `auditor` column is `true`
      # and the auditor add-on absent. We want to run this validation
      # regardless of the add-on's presence, so we need to check the `auditor`
      # column directly.
      validate :auditor_requires_license_add_on, if: :auditor
      validate :cannot_be_admin_and_auditor

      delegate :shared_runners_minutes_limit, :shared_runners_minutes_limit=,
               :extra_shared_runners_minutes_limit, :extra_shared_runners_minutes_limit=,
               to: :namespace

      has_many :reviews,                  foreign_key: :author_id, inverse_of: :author
      has_many :epics,                    foreign_key: :author_id
      has_many :assigned_epics,           foreign_key: :assignee_id, class_name: "Epic"
      has_many :path_locks,               dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :vulnerability_feedback, foreign_key: :author_id, class_name: 'Vulnerabilities::Feedback'
      has_many :commented_vulnerability_feedback, foreign_key: :comment_author_id, class_name: 'Vulnerabilities::Feedback'

      has_many :approvals,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :approvers,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent

      has_many :developer_groups, -> { where(members: { access_level: ::Gitlab::Access::DEVELOPER }) }, through: :group_members, source: :group

      has_many :users_ops_dashboard_projects
      has_many :ops_dashboard_projects, through: :users_ops_dashboard_projects, source: :project

      has_many :group_saml_identities, -> { where.not(saml_provider_id: nil) }, source: :identities, class_name: "::Identity"

      # Protected Branch Access
      has_many :protected_branch_merge_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::MergeAccessLevel" # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_push_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::PushAccessLevel" # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_unprotect_access_levels, dependent: :destroy, class_name: "::ProtectedBranch::UnprotectAccessLevel" # rubocop:disable Cop/ActiveRecordDependent

      has_many :smartcard_identities

      belongs_to :managing_group, class_name: 'Group', optional: true, inverse_of: :managed_users

      scope :not_managed, ->(group: nil) {
        scope = where(managing_group_id: nil)
        scope = scope.or(where.not(managing_group_id: group.id)) if group
        scope
      }

      scope :excluding_guests, -> { joins(:members).where('members.access_level > ?', ::Gitlab::Access::GUEST).distinct }

      scope :subscribed_for_admin_email, -> { where(admin_email_unsubscribed_at: nil) }
      scope :ldap, -> { joins(:identities).where('identities.provider LIKE ?', 'ldap%') }
      scope :with_provider, ->(provider) do
        joins(:identities).where(identities: { provider: provider })
      end

      scope :bots, -> { where.not(bot_type: nil) }
      scope :humans, -> { where(bot_type: nil) }

      accepts_nested_attributes_for :namespace

      enum roadmap_layout: { weeks: 1, months: 4, quarters: 12 }

      # User's Group preference
      # Note: When adding an option, it's value MUST equal to the last value + 1.
      enum group_view: { details: 1, security_dashboard: 2 }, _prefix: true
      scope :group_view_details, -> { where('group_view = ? OR group_view IS NULL', group_view[:details]) }

      enum bot_type: {
        support_bot: 1,
        alert_bot: 2
      }
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      def support_bot
        email_pattern = "support%s@#{Settings.gitlab.host}"

        unique_internal(where(bot_type: :support_bot), 'support-bot', email_pattern) do |u|
          u.bio = 'The GitLab support bot used for Service Desk'
          u.name = 'GitLab Support Bot'
        end
      end

      def alert_bot
        email_pattern = "alert%s@#{Settings.gitlab.host}"

        unique_internal(where(bot_type: :alert_bot), 'alert-bot', email_pattern) do |u|
          u.bio = 'The GitLab alert bot'
          u.name = 'GitLab Alert Bot'
        end
      end

      override :internal
      def internal
        super.or(where.not(bot_type: nil))
      end

      override :non_internal
      def non_internal
        super.where(bot_type: nil)
      end

      def non_ldap
        joins('LEFT JOIN identities ON identities.user_id = users.id')
          .where('identities.provider IS NULL OR identities.provider NOT LIKE ?', 'ldap%')
      end

      def find_by_smartcard_identity(certificate_subject, certificate_issuer)
        joins(:smartcard_identities)
          .find_by(smartcard_identities: { subject: certificate_subject, issuer: certificate_issuer })
      end

      def username_suggestion(base_name)
        suffix = nil
        base_name = base_name.parameterize(separator: '_')
        MAX_USERNAME_SUGGESTION_ATTEMPTS.times do |attempt|
          username = "#{base_name}#{suffix}"
          return username unless ::Namespace.find_by_path_or_name(username)

          suffix = attempt + 1
        end

        ''
      end
    end

    def cannot_be_admin_and_auditor
      if admin? && auditor?
        errors.add(:admin, "user cannot also be an Auditor.")
      end
    end

    def auditor_requires_license_add_on
      unless license_allows_auditor_user?
        errors.add(:auditor, 'user cannot be created without the "GitLab_Auditor_User" addon')
      end
    end

    def auditor?
      self.auditor && license_allows_auditor_user?
    end

    def access_level
      if auditor?
        :auditor
      else
        super
      end
    end

    def access_level=(new_level)
      new_level = new_level.to_s
      return unless %w(admin auditor regular).include?(new_level)

      self.admin = (new_level == 'admin')
      self.auditor = (new_level == 'auditor')
    end

    # Does the user have access to all private groups & projects?
    def full_private_access?
      super || auditor?
    end

    def email_opted_in_source
      email_opted_in_source_id == EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM ? 'GitLab.com' : ''
    end

    def available_custom_project_templates(search: nil, subgroup_id: nil)
      templates = ::Gitlab::CurrentSettings.available_custom_project_templates(subgroup_id)

      ::ProjectsFinder.new(current_user: self,
                           project_ids_relation: templates,
                           params: { search: search, sort: 'name_asc' })
                      .execute
    end

    def available_subgroups_with_custom_project_templates(group_id = nil)
      groups = GroupsWithTemplatesFinder.new(group_id).execute

      GroupsFinder.new(self, min_access_level: ::Gitlab::Access::DEVELOPER)
                  .execute
                  .where(id: groups.select(:custom_project_templates_group_id))
                  .includes(:projects)
                  .reorder(nil)
                  .distinct
    end

    def roadmap_layout
      super || DEFAULT_ROADMAP_LAYOUT
    end

    def group_view
      super || DEFAULT_GROUP_VIEW
    end

    def any_namespace_with_trial?
      ::Namespace
        .from("(#{namespace_union(:trial_ends_on)}) #{::Namespace.table_name}")
        .where('trial_ends_on > ?', Time.now.utc)
        .any?
    end

    def any_namespace_with_gold?
      ::Namespace
        .includes(:plan)
        .where("namespaces.id IN (#{namespace_union})") # rubocop:disable GitlabSecurity/SqlInjection
        .where.not(plans: { id: nil })
        .any?
    end

    override :has_current_license?
    def has_current_license?
      License.current.present?
    end

    def using_license_seat?
      return false unless active?

      if License.current&.exclude_guests_from_active_count?
        highest_role > ::Gitlab::Access::GUEST
      else
        highest_role > ::Gitlab::Access::NO_ACCESS
      end
    end

    def group_sso?(group)
      return false unless group

      if group_saml_identities.loaded?
        group_saml_identities.any? { |identity| identity.saml_provider.group_id == group.id }
      else
        group_saml_identities.where(saml_provider: group.saml_provider).any?
      end
    end

    def group_managed_account?
      managing_group.present?
    end

    override :ldap_sync_time
    def ldap_sync_time
      ::Gitlab.config.ldap['sync_time']
    end

    def admin_unsubscribe!
      update_column :admin_email_unsubscribed_at, Time.now
    end

    override :allow_password_authentication_for_web?
    def allow_password_authentication_for_web?(*)
      return false if group_managed_account?

      super
    end

    override :allow_password_authentication_for_git?
    def allow_password_authentication_for_git?(*)
      return false if group_managed_account?

      super
    end

    def internal?
      super || bot?
    end

    def bot?
      return bot_type.present? if has_attribute?(:bot_type)

      # Some older *migration* specs utilize this removed column
      read_attribute(:support_bot)
    end

    protected

    override :password_required?
    def password_required?(*)
      return false if group_managed_account?

      super
    end

    private

    def namespace_union(select = :id)
      ::Gitlab::SQL::Union.new([
        ::Namespace.select(select).where(type: nil, owner: self),
        owned_groups.select(select).where(parent_id: nil)
      ]).to_sql
    end
  end
end
