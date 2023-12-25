# frozen_string_literal: true

module API
  class ProjectApprovalSettings < ::Grape::API
    before { authenticate! }

    helpers ::API::Helpers::ProjectApprovalRulesHelpers

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/approval_settings' do
        desc 'Get all project approval rules' do
          detail 'Private API subject to change'
          success EE::API::Entities::ProjectApprovalSettings
        end
        get do
          authorize_create_merge_request_in_project

          present user_project, with: EE::API::Entities::ProjectApprovalSettings, current_user: current_user
        end

        segment 'rules' do
          desc 'Create new approval rule' do
            detail 'Private API subject to change'
            success EE::API::Entities::ApprovalSettingRule
          end
          params do
            use :create_project_approval_rule
          end
          post do
            create_project_approval_rule(present_with: EE::API::Entities::ApprovalSettingRule)
          end

          segment ':approval_rule_id' do
            desc 'Update approval rule' do
              detail 'Private API subject to change'
              success EE::API::Entities::ApprovalSettingRule
            end
            params do
              use :update_project_approval_rule
            end
            put do
              update_project_approval_rule(present_with: EE::API::Entities::ApprovalSettingRule)
            end

            desc 'Delete an approval rule' do
              detail 'Private API subject to change'
            end
            params do
              use :delete_project_approval_rule
            end
            delete do
              destroy_project_approval_rule
            end
          end
        end
      end
    end
  end
end
