# frozen_string_literal: true

module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Project` model
  module Project
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    extend ::Gitlab::Cache::RequestCache
    include ::Gitlab::Utils::StrongMemoize
    include ::EE::GitlabRoutingHelper # rubocop: disable Cop/InjectEnterpriseEditionModule

    GIT_LFS_DOWNLOAD_OPERATION = 'download'.freeze

    prepended do
      include Elastic::ProjectsSearch
      include EE::DeploymentPlatform # rubocop: disable Cop/InjectEnterpriseEditionModule
      include EachBatch
      include InsightsFeature
      include Vulnerable
      include DeprecatedApprovalsBeforeMerge

      self.ignored_columns += %i[
        mirror_last_update_at
        mirror_last_successful_update_at
      ]

      before_save :set_override_pull_mirror_available, unless: -> { ::Gitlab::CurrentSettings.mirror_available }
      before_save :set_next_execution_timestamp_to_now, if: ->(project) { project.mirror? && project.mirror_changed? && project.import_state }

      after_update :remove_mirror_repository_reference,
        if: ->(project) { project.mirror? && project.import_url_updated? }

      belongs_to :mirror_user, foreign_key: 'mirror_user_id', class_name: 'User'

      has_one :repository_state, class_name: 'ProjectRepositoryState', inverse_of: :project
      has_one :project_registry, class_name: 'Geo::ProjectRegistry', inverse_of: :project
      has_one :push_rule, ->(project) { project&.feature_available?(:push_rules) ? all : none }
      has_one :index_status
      has_one :jenkins_service
      has_one :jenkins_deprecated_service
      has_one :github_service
      has_one :gitlab_slack_application_service
      has_one :tracing_setting, class_name: 'ProjectTracingSetting'
      has_one :alerting_setting, inverse_of: :project, class_name: 'Alerting::ProjectAlertingSetting'
      has_one :incident_management_setting, inverse_of: :project, class_name: 'IncidentManagement::ProjectIncidentManagementSetting'
      has_one :feature_usage, class_name: 'ProjectFeatureUsage'

      has_many :reviews, inverse_of: :project
      has_many :approvers, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_users, through: :approvers, source: :user
      has_many :approver_groups, as: :target, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
      has_many :approval_rules, class_name: 'ApprovalProjectRule'
      has_many :approval_merge_request_rules, through: :merge_requests, source: :approval_rules
      has_many :audit_events, as: :entity
      has_many :designs, inverse_of: :project, class_name: 'DesignManagement::Design'
      has_many :path_locks
      has_many :vulnerability_feedback, class_name: 'Vulnerabilities::Feedback'
      has_many :vulnerabilities, class_name: 'Vulnerabilities::Occurrence'
      has_many :vulnerability_identifiers, class_name: 'Vulnerabilities::Identifier'
      has_many :vulnerability_scanners, class_name: 'Vulnerabilities::Scanner'
      has_many :protected_environments
      has_many :software_license_policies, inverse_of: :project, class_name: 'SoftwareLicensePolicy'
      accepts_nested_attributes_for :software_license_policies, allow_destroy: true
      has_many :packages, class_name: 'Packages::Package'
      has_many :package_files, through: :packages, class_name: 'Packages::PackageFile'
      has_many :merge_trains, foreign_key: 'target_project_id', inverse_of: :target_project

      has_many :sourced_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :source_project_id

      has_many :source_pipelines, class_name: 'Ci::Sources::Pipeline', foreign_key: :project_id

      has_many :webide_pipelines, -> { webide_source }, class_name: 'Ci::Pipeline', inverse_of: :project

      has_many :prometheus_alerts, inverse_of: :project
      has_many :prometheus_alert_events, inverse_of: :project

      has_many :operations_feature_flags, class_name: 'Operations::FeatureFlag'
      has_one :operations_feature_flags_client, class_name: 'Operations::FeatureFlagsClient'

      has_many :project_aliases

      scope :with_shared_runners_limit_enabled, -> { with_shared_runners.non_public_only }

      scope :mirror, -> { where(mirror: true) }

      scope :mirrors_to_sync, ->(freeze_at, limit: nil) do
        mirror
          .joins_import_state
          .where.not(import_state: { status: [:scheduled, :started] })
          .where("import_state.next_execution_timestamp <= ?", freeze_at)
          .where("import_state.retry_count <= ?", ::Gitlab::Mirror::MAX_RETRY)
          .limit(limit)
      end

      scope :with_wiki_enabled, -> { with_feature_enabled(:wiki) }
      scope :within_shards, -> (shard_names) { where(repository_storage: Array(shard_names)) }
      scope :outside_shards, -> (shard_names) { where.not(repository_storage: Array(shard_names)) }
      scope :verification_failed_repos, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_repos) }
      scope :verification_failed_wikis, -> { joins(:repository_state).merge(ProjectRepositoryState.verification_failed_wikis) }
      scope :for_plan_name, -> (name) { joins(namespace: :plan).where(plans: { name: name }) }
      scope :requiring_code_owner_approval,
            -> { where(merge_requests_require_code_owner_approval: true) }

      scope :with_security_reports_stored, -> { where('EXISTS (?)', ::Vulnerabilities::Occurrence.scoped_project.select(1)) }
      scope :with_security_reports, -> { where('EXISTS (?)', ::Ci::JobArtifact.security_reports.scoped_project.select(1)) }

      delegate :shared_runners_minutes, :shared_runners_seconds, :shared_runners_seconds_last_reset,
        to: :statistics, allow_nil: true

      delegate :actual_shared_runners_minutes_limit,
        :shared_runners_minutes_used?, to: :shared_runners_limit_namespace

      delegate :last_update_succeeded?, :last_update_failed?,
        :ever_updated_successfully?, :hard_failed?,
        to: :import_state, prefix: :mirror, allow_nil: true

      delegate :log_jira_dvcs_integration_usage, :jira_dvcs_server_last_sync_at, :jira_dvcs_cloud_last_sync_at, to: :feature_usage

      delegate :merge_pipelines_enabled, :merge_pipelines_enabled=, :merge_pipelines_enabled?, to: :ci_cd_settings
      delegate :merge_trains_enabled, :merge_trains_enabled=, :merge_trains_enabled?, to: :ci_cd_settings

      validates :repository_size_limit,
        numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }

      validates :approvals_before_merge, numericality: true, allow_blank: true

      with_options if: :mirror? do
        validates :import_url, presence: true
        validates :mirror_user, presence: true
      end

      default_value_for :packages_enabled, true

      delegate :store_security_reports_available?, to: :namespace

      accepts_nested_attributes_for :tracing_setting, update_only: true, allow_destroy: true
      accepts_nested_attributes_for :alerting_setting, update_only: true
      accepts_nested_attributes_for :incident_management_setting, update_only: true

      alias_attribute :fallback_approvals_required, :approvals_before_merge
    end

    class_methods do
      def search_by_visibility(level)
        where(visibility_level: ::Gitlab::VisibilityLevel.string_options[level])
      end

      def with_slack_application_disabled
        joins('LEFT JOIN services ON services.project_id = projects.id AND services.type = \'GitlabSlackApplicationService\' AND services.active IS true')
          .where('services.id IS NULL')
      end
    end

    def tracing_external_url
      self.tracing_setting.try(:external_url)
    end

    def latest_pipeline_with_security_reports
      all_pipelines.newest_first(ref: default_branch).with_reports(::Ci::JobArtifact.security_reports).first ||
        all_pipelines.newest_first(ref: default_branch).with_legacy_security_reports.first
    end

    def environments_for_scope(scope)
      quoted_scope = ::Gitlab::SQL::Glob.q(scope)

      environments.where("name LIKE (#{::Gitlab::SQL::Glob.to_like(quoted_scope)})") # rubocop:disable GitlabSecurity/SqlInjection
    end

    def ensure_external_webhook_token
      return if external_webhook_token.present?

      self.external_webhook_token = Devise.friendly_token
    end

    def shared_runners_limit_namespace
      root_namespace
    end

    def mirror
      super && feature_available?(:repository_mirrors) && pull_mirror_available?
    end
    alias_method :mirror?, :mirror

    def mirror_with_content?
      mirror? && !empty_repo?
    end

    def fetch_mirror(forced: false)
      return unless mirror?

      # Only send the password if it's needed
      url =
        if import_data&.password_auth?
          import_url
        else
          username_only_import_url
        end

      repository.fetch_upstream(url, forced: forced)
    end

    def can_override_approvers?
      !disable_overriding_approvers_per_merge_request?
    end

    def shared_runners_available?
      super && !shared_runners_limit_namespace.shared_runners_minutes_used?
    end

    def link_pool_repository
      super
      repository.log_geo_updated_event
    end

    def object_pool_missing?
      has_pool_repository? && !pool_repository.object_pool.exists?
    end

    def shared_runners_minutes_limit_enabled?
      !public? && shared_runners_enabled? &&
        shared_runners_limit_namespace.shared_runners_minutes_limit_enabled?
    end

    # This makes the feature disabled by default, in contrary to how
    # `#feature_available?` makes a feature enabled by default.
    #
    # This allows to:
    # - Enable the feature flag for a given project, regardless of the license.
    #   This is useful for early testing a feature in production on a given project.
    # - Enable the feature flag globally and still check that the license allows
    #   it. This is the case when we're ready to enable a feature for anyone
    #   with the correct license.
    def beta_feature_available?(feature)
      ::Feature.enabled?(feature, self) ||
        (::Feature.enabled?(feature) && feature_available?(feature))
    end

    def push_audit_events_enabled?
      ::Feature.enabled?(:repository_push_audit_event, self)
    end

    def feature_available?(feature, user = nil)
      if ::ProjectFeature::FEATURES.include?(feature)
        super
      else
        licensed_feature_available?(feature, user)
      end
    end

    def multiple_approval_rules_available?
      feature_available?(:multiple_approval_rules)
    end

    def code_owner_approval_required_available?
      feature_available?(:code_owner_approval_required)
    end

    def service_desk_enabled
      ::EE::Gitlab::ServiceDesk.enabled?(project: self) && super
    end
    alias_method :service_desk_enabled?, :service_desk_enabled

    def service_desk_address
      return unless service_desk_enabled?

      config = ::Gitlab.config.incoming_email
      wildcard = ::Gitlab::IncomingEmail::WILDCARD_PLACEHOLDER

      config.address&.gsub(wildcard, "#{full_path_slug}-#{id}-issue-")
    end

    override :add_import_job
    def add_import_job
      return if gitlab_custom_project_template_import?

      if import? && !repository_exists?
        super
      elsif mirror?
        ::Gitlab::Metrics.add_event(:mirrors_scheduled)
        job_id = RepositoryUpdateMirrorWorker.perform_async(self.id)

        log_import_activity(job_id, type: :mirror)

        job_id
      end
    end

    override :has_active_hooks?
    def has_active_hooks?(hooks_scope = :push_hooks)
      super || has_group_hooks?(hooks_scope)
    end

    def has_group_hooks?(hooks_scope = :push_hooks)
      return unless group && feature_available?(:group_webhooks)

      group.hooks.hooks_for(hooks_scope).any?
    end

    def execute_hooks(data, hooks_scope = :push_hooks)
      super

      if group && feature_available?(:group_webhooks)
        run_after_commit_or_now do
          group.hooks.hooks_for(hooks_scope).each do |hook|
            hook.async_execute(data, hooks_scope.to_s)
          end
        end
      end
    end

    # No need to have a Kerberos Web url. Kerberos URL will be used only to
    # clone
    def kerberos_url_to_repo
      "#{::Gitlab.config.build_gitlab_kerberos_url + ::Gitlab::Routing.url_helpers.project_path(self)}.git"
    end

    def group_ldap_synced?
      group&.ldap_synced?
    end

    override :allowed_to_share_with_group?
    def allowed_to_share_with_group?
      super && !(group && ::Gitlab::CurrentSettings.lock_memberships_to_ldap?)
    end

    def reference_issue_tracker?
      default_issues_tracker? || jira_tracker_active?
    end

    def approvals_before_merge
      return 0 unless feature_available?(:merge_request_approvers)

      super
    end

    def visible_approval_rules
      strong_memoize(:visible_approval_rules) do
        visible_regular_approval_rules + approval_rules.report_approver
      end
    end

    def visible_regular_approval_rules
      strong_memoize(:visible_regular_approval_rules) do
        regular_rules = approval_rules.regular.order(:id)

        next regular_rules.take(1) unless multiple_approval_rules_available?

        regular_rules
      end
    end

    def min_fallback_approvals
      strong_memoize(:min_fallback_approvals) do
        visible_regular_approval_rules.map(&:approvals_required).max ||
          approvals_before_merge.to_i
      end
    end

    def reset_approvals_on_push
      super && feature_available?(:merge_request_approvers)
    end
    alias_method :reset_approvals_on_push?, :reset_approvals_on_push

    def approver_ids=(value)
      ::Gitlab::Utils.ensure_array_from_string(value).each do |user_id|
        approvers.find_or_create_by(user_id: user_id, target_id: id)
      end
    end

    def approver_group_ids=(value)
      ::Gitlab::Utils.ensure_array_from_string(value).each do |group_id|
        approver_groups.find_or_initialize_by(group_id: group_id, target_id: id)
      end
    end

    def merge_requests_require_code_owner_approval?
      super && code_owner_approval_required_available?
    end

    def branch_requires_code_owner_approval?(branch_name)
      return false unless code_owner_approval_required_available?

      protected_branches.requiring_code_owner_approval.matching(branch_name).any?
    end

    def require_password_to_approve
      super && password_authentication_enabled_for_web?
    end
    alias_method :require_password_to_approve?, :require_password_to_approve

    def find_path_lock(path, exact_match: false, downstream: false)
      path_lock_finder = strong_memoize(:path_lock_finder) do
        ::Gitlab::PathLocksFinder.new(self)
      end

      path_lock_finder.find(path, exact_match: exact_match, downstream: downstream)
    end

    def import_url_updated?
      # check if import_url has been updated and it's not just the first assignment
      saved_change_to_import_url? && saved_changes['import_url'].first
    end

    def remove_mirror_repository_reference
      run_after_commit do
        repository.async_remove_remote(::Repository::MIRROR_REMOTE)
      end
    end

    def username_only_import_url
      bare_url = read_attribute(:import_url)
      return bare_url unless ::Gitlab::UrlSanitizer.valid?(bare_url)

      ::Gitlab::UrlSanitizer.new(bare_url, credentials: { user: import_data&.user }).full_url
    end

    def username_only_import_url=(value)
      unless ::Gitlab::UrlSanitizer.valid?(value)
        self.import_url = value
        self.import_data&.user = nil
        value
      end

      url = ::Gitlab::UrlSanitizer.new(value)
      creds = url.credentials.slice(:user)

      write_attribute(:import_url, url.sanitized_url)
      create_or_update_import_data(credentials: creds)

      username_only_import_url
    end

    def change_repository_storage(new_repository_storage_key)
      return if repository_read_only?
      return if repository_storage == new_repository_storage_key

      raise ArgumentError unless ::Gitlab.config.repositories.storages.key?(new_repository_storage_key)

      run_after_commit { ProjectUpdateRepositoryStorageWorker.perform_async(id, new_repository_storage_key) }
      self.repository_read_only = true
    end

    def repository_and_lfs_size
      statistics.total_repository_size
    end

    def above_size_limit?
      return false unless size_limit_enabled?

      repository_and_lfs_size > actual_size_limit
    end

    def size_to_remove
      repository_and_lfs_size - actual_size_limit
    end

    def actual_size_limit
      return namespace.actual_size_limit if repository_size_limit.nil?

      repository_size_limit
    end

    def size_limit_enabled?
      return false unless License.feature_available?(:repository_size_limit)

      actual_size_limit != 0
    end

    def changes_will_exceed_size_limit?(size_in_bytes)
      size_limit_enabled? &&
        (size_in_bytes > actual_size_limit ||
         size_in_bytes + repository_and_lfs_size > actual_size_limit)
    end

    def remove_import_data
      super unless mirror?
    end

    def merge_requests_ff_only_enabled
      super
    end
    alias_method :merge_requests_ff_only_enabled?, :merge_requests_ff_only_enabled

    override :disabled_services
    def disabled_services
      strong_memoize(:disabled_services) do
        disabled_services = []

        unless feature_available?(:jenkins_integration)
          disabled_services.push('jenkins', 'jenkins_deprecated')
        end

        unless feature_available?(:github_project_service_integration)
          disabled_services.push('github')
        end

        disabled_services
      end
    end

    def pull_mirror_available?
      pull_mirror_available_overridden ||
        ::Gitlab::CurrentSettings.mirror_available
    end

    override :licensed_features
    def licensed_features
      return super unless License.current

      License.current.features.select do |feature|
        License.global_feature?(feature) || licensed_feature_available?(feature)
      end
    end

    def any_path_locks?
      path_locks.any?
    end
    request_cache(:any_path_locks?) { self.id }

    def protected_environment_accessible_to?(environment_name, user)
      protected_environment = protected_environment_by_name(environment_name)

      !protected_environment || protected_environment.accessible_to?(user)
    end

    def protected_environment_by_name(environment_name)
      return unless protected_environments_feature_available?

      protected_environments.find_by(name: environment_name)
    end

    override :after_import
    def after_import
      super
      repository.log_geo_updated_event
      wiki.repository.log_geo_updated_event
    end

    override :import?
    def import?
      super || gitlab_custom_project_template_import?
    end

    def gitlab_custom_project_template_import?
      import_type == 'gitlab_custom_project_template' &&
        ::Gitlab::CurrentSettings.custom_project_templates_enabled?
    end

    def protected_environments_feature_available?
      feature_available?(:protected_environments)
    end

    # Because we use default_value_for we need to be sure
    # packages_enabled= method does exist even if we rollback migration.
    # Otherwise many tests from spec/migrations will fail.
    def packages_enabled=(value)
      if has_attribute?(:packages_enabled)
        write_attribute(:packages_enabled, value)
      end
    end

    # Update the default branch querying the remote to determine its HEAD
    def update_root_ref(remote_name)
      root_ref = repository.find_remote_root_ref(remote_name)
      change_head(root_ref) if root_ref.present?
    end

    def feature_flags_client_token
      instance = operations_feature_flags_client || create_operations_feature_flags_client!
      instance.token
    end

    def root_namespace
      if namespace.has_parent?
        namespace.root_ancestor
      else
        namespace
      end
    end

    def active_webide_pipelines(user:)
      webide_pipelines.running_or_pending.for_user(user)
    end

    override :lfs_http_url_to_repo
    def lfs_http_url_to_repo(operation)
      return super unless ::Gitlab::Geo.secondary_with_primary?
      return super if operation == GIT_LFS_DOWNLOAD_OPERATION # download always comes from secondary

      geo_primary_http_url_to_repo(self)
    end

    def feature_usage
      super.presence || build_feature_usage
    end

    def design_management_enabled?
      # LFS is required for using Design Management
      #
      # Checking both feature availability on the license, as well as the feature
      # flag, because we don't want to enable design_management by default on
      # on prem installs yet.
      lfs_enabled? &&
        feature_available?(:design_management) &&
        ::Feature.enabled?(:design_management_flag, self, default_enabled: true)
    end

    def design_repository
      @design_repository ||= DesignManagement::Repository.new(self)
    end

    def package_already_taken?(package_name)
      namespace.root_ancestor.all_projects
        .joins(:packages)
        .where.not(id: id)
        .merge(Packages::Package.with_name(package_name))
        .exists?
    end

    private

    def set_override_pull_mirror_available
      self.pull_mirror_available_overridden = read_attribute(:mirror)
      true
    end

    def set_next_execution_timestamp_to_now
      import_state.set_next_execution_to_now
    end

    def licensed_feature_available?(feature, user = nil)
      # This feature might not be behind a feature flag at all, so default to true
      return false unless ::Feature.enabled?(feature, user, default_enabled: true)

      available_features = strong_memoize(:licensed_feature_available) do
        Hash.new do |h, f|
          h[f] = load_licensed_feature_available(f)
        end
      end

      available_features[feature]
    end

    def load_licensed_feature_available(feature)
      globally_available = License.feature_available?(feature)

      if ::Gitlab::CurrentSettings.should_check_namespace_plan? && namespace
        globally_available &&
          (public? && namespace.public? || namespace.feature_available_in_plan?(feature))
      else
        globally_available
      end
    end

    def validate_board_limit(board)
      # Board limits are disabled in EE, so this method is just a no-op.
    end
  end
end
