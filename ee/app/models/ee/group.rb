# frozen_string_literal: true

module EE
  # Group EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be included in the `Group` model
  module Group
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include Vulnerable
      include TokenAuthenticatable
      include InsightsFeature

      add_authentication_token_field :saml_discovery_token, unique: false, token_generator: -> { Devise.friendly_token(8) }

      has_many :epics

      has_one :saml_provider
      has_many :ip_restrictions, autosave: true
      has_one :insight, foreign_key: :namespace_id
      accepts_nested_attributes_for :insight, allow_destroy: true
      has_one :scim_oauth_access_token

      has_many :ldap_group_links, foreign_key: 'group_id', dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :hooks, dependent: :destroy, class_name: 'GroupHook' # rubocop:disable Cop/ActiveRecordDependent

      has_one :dependency_proxy_setting, class_name: 'DependencyProxy::GroupSetting'
      has_many :dependency_proxy_blobs, class_name: 'DependencyProxy::Blob'

      has_one :allowed_email_domain
      accepts_nested_attributes_for :allowed_email_domain, allow_destroy: true, reject_if: :all_blank

      # We cannot simply set `has_many :audit_events, as: :entity, dependent: :destroy`
      # here since Group inherits from Namespace, the entity_type would be set to `Namespace`.
      has_many :audit_events, -> { where(entity_type: ::Group.name) }, foreign_key: 'entity_id'

      has_many :project_templates, through: :projects, foreign_key: 'custom_project_templates_group_id'

      has_many :managed_users, class_name: 'User', foreign_key: 'managing_group_id', inverse_of: :managing_group
      has_many :cycle_analytics_stages, class_name: 'Analytics::CycleAnalytics::GroupStage'

      belongs_to :file_template_project, class_name: "Project"

      # Use +checked_file_template_project+ instead, which implements important
      # visibility checks
      private :file_template_project

      validates :repository_size_limit,
                numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }

      validate :custom_project_templates_group_allowed, if: :custom_project_templates_group_id_changed?

      scope :where_group_links_with_provider, ->(provider) do
        joins(:ldap_group_links).where(ldap_group_links: { provider: provider })
      end

      scope :with_project_templates, -> do
        joins("INNER JOIN projects ON projects.namespace_id = namespaces.custom_project_templates_group_id")
        .distinct
      end

      scope :with_custom_file_templates, -> do
        preload(
          file_template_project: :route,
          projects: :route,
          shared_projects: :route
        ).where.not(file_template_project_id: nil)
      end

      state_machine :ldap_sync_status, namespace: :ldap_sync, initial: :ready do
        state :ready
        state :started
        state :pending
        state :failed

        event :pending do
          transition [:ready, :failed] => :pending
        end

        event :start do
          transition [:ready, :pending, :failed] => :started
        end

        event :finish do
          transition started: :ready
        end

        event :fail do
          transition started: :failed
        end

        after_transition ready: :started do |group, _|
          group.ldap_sync_last_sync_at = DateTime.now
          group.save
        end

        after_transition started: :ready do |group, _|
          current_time = DateTime.now
          group.ldap_sync_last_update_at = current_time
          group.ldap_sync_last_successful_update_at = current_time
          group.ldap_sync_error = nil
          group.save
        end

        after_transition started: :failed do |group, _|
          group.ldap_sync_last_update_at = DateTime.now
          group.save
        end
      end
    end

    def ip_restriction_ranges
      return unless ip_restrictions.present?

      ip_restrictions.map(&:range).join(",")
    end

    def human_ldap_access
      ::Gitlab::Access.options_with_owner.key(ldap_access)
    end

    # NOTE: Backwards compatibility with old ldap situation
    def ldap_cn
      ldap_group_links.first.try(:cn)
    end

    def ldap_access
      ldap_group_links.first.try(:group_access)
    end

    override :ldap_synced?
    def ldap_synced?
      (::Gitlab.config.ldap.enabled && ldap_group_links.any?(&:active?)) || super
    end

    def mark_ldap_sync_as_failed(error_message, skip_validation: false)
      return false unless ldap_sync_started?

      error_message = ::Gitlab::UrlSanitizer.sanitize(error_message)

      if skip_validation
        # A group that does not validate cannot transition out of its
        # current state, so manually set the ldap_sync_status
        update_columns(ldap_sync_error: error_message,
                       ldap_sync_status: 'failed')
      else
        fail_ldap_sync
        update_column(:ldap_sync_error, error_message)
      end
    end

    # This token conveys that the anonymous user is allowed to know of the group
    # Used to avoid revealing that a group exists on a given path
    def saml_discovery_token
      ensure_saml_discovery_token!
    end

    override :multiple_issue_boards_available?
    def multiple_issue_boards_available?
      feature_available?(:multiple_group_issue_boards)
    end

    def group_project_template_available?
      feature_available?(:group_project_templates) ||
        (custom_project_templates_group_id? && Time.zone.now <= GroupsWithTemplatesFinder::CUT_OFF_DATE)
    end

    def actual_size_limit
      return ::Gitlab::CurrentSettings.repository_size_limit if repository_size_limit.nil?

      repository_size_limit
    end

    def first_non_empty_project
      projects.detect { |project| !project.empty_repo? }
    end

    def project_ids_with_security_reports
      all_projects.with_security_reports_stored.pluck_primary_key
    end

    def root_ancestor_ip_restrictions
      return ip_restrictions if parent_id.nil?

      root_ancestor.ip_restrictions
    end

    def root_ancestor_allowed_email_domain
      return allowed_email_domain if parent_id.nil?

      root_ancestor.allowed_email_domain
    end

    # Overrides a method defined in `::EE::Namespace`
    override :checked_file_template_project
    def checked_file_template_project(*args, &blk)
      project = file_template_project(*args, &blk)

      return unless project && (
          project_ids.include?(project.id) || shared_project_ids.include?(project.id))

      # The license check would normally be the cheapest to perform, so would
      # come first. In this case, the method is carefully designed to perform
      # no SQL at all, but `feature_available?` will cause an ApplicationSetting
      # to be created if it doesn't already exist! This is mostly a problem in
      # the specs, but best avoided in any case.
      return unless feature_available?(:custom_file_templates_for_namespace)

      project
    end

    # For now, we are not billing for members with a Guest role for subscriptions
    # with a Gold plan. The other plans will treat Guest members as a regular member
    # for billing purposes.
    override :billable_members_count
    def billable_members_count(requested_hosted_plan = nil)
      if [actual_plan_name, requested_hosted_plan].include?(Namespace::GOLD_PLAN)
        users_with_descendants.excluding_guests.count
      else
        users_with_descendants.count
      end
    end

    def packages_feature_available?
      ::Gitlab.config.packages.enabled && feature_available?(:packages)
    end

    def dependency_proxy_feature_available?
      ::Gitlab.config.dependency_proxy.enabled && feature_available?(:dependency_proxy)
    end

    private

    def custom_project_templates_group_allowed
      return if custom_project_templates_group_id.blank?
      return if children.exists?(id: custom_project_templates_group_id)

      errors.add(:custom_project_templates_group_id, "has to be a subgroup of the group")
    end
  end
end
