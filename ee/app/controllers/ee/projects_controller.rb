# frozen_string_literal: true

module EE
  module ProjectsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      before_action :log_download_export_audit_event, only: [:download_export]
      before_action :log_archive_audit_event, only: [:archive]
      before_action :log_unarchive_audit_event, only: [:unarchive]
    end

    override :project_params_attributes
    def project_params_attributes
      super + project_params_ee
    end

    override :custom_import_params
    def custom_import_params
      custom_params = super
      ci_cd_param   = params.dig(:project, :ci_cd_only) || params[:ci_cd_only]

      custom_params[:ci_cd_only] = ci_cd_param if ci_cd_param == 'true'
      custom_params
    end

    override :active_new_project_tab
    def active_new_project_tab
      project_params[:ci_cd_only] == 'true' ? 'ci_cd_only' : super
    end

    private

    def project_params_ee
      attrs = %i[
        approvals_before_merge
        approver_group_ids
        approver_ids
        issues_template
        merge_requests_template
        disable_overriding_approvers_per_merge_request
        repository_size_limit
        reset_approvals_on_push
        service_desk_enabled
        ci_cd_only
        use_custom_template
        packages_enabled
        merge_requests_author_approval
        merge_requests_disable_committers_approval
        require_password_to_approve
        merge_requests_require_code_owner_approval
        group_with_project_templates_id
      ]

      if allow_merge_pipelines_params?
        attrs << %i[merge_pipelines_enabled]
      end

      if allow_mirror_params?
        attrs + mirror_params
      else
        attrs
      end
    end

    def mirror_params
      %i[
        mirror
        mirror_trigger_builds
        mirror_user_id
      ]
    end

    def allow_mirror_params?
      if @project # rubocop:disable Gitlab/ModuleWithInstanceVariables
        can?(current_user, :admin_mirror, @project) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      else
        ::Gitlab::CurrentSettings.current_application_settings.mirror_available || current_user&.admin?
      end
    end

    def allow_merge_pipelines_params?
      project&.feature_available?(:merge_pipelines)
    end

    def log_audit_event(message:)
      AuditEvents::CustomAuditEventService.new(
        current_user,
        project,
        request.remote_ip,
        message
      ).for_project.security_event
    end

    def log_download_export_audit_event
      log_audit_event(message: 'Export file download started')
    end

    def log_archive_audit_event
      log_audit_event(message: 'Project archived')
    end

    def log_unarchive_audit_event
      log_audit_event(message: 'Project unarchived')
    end
  end
end
