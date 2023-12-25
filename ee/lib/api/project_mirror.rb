# frozen_string_literal: true

require_dependency 'declarative_policy'

module API
  class ProjectMirror < Grape::API
    helpers do
      def github_webhook_signature
        @github_webhook_signature ||= headers['X-Hub-Signature']
      end

      def authenticate_from_github_webhook!
        return unless github_webhook_signature

        unless valid_github_signature?
          Guest.can?(:read_project, project) ? unauthorized! : not_found!
        end
      end

      def valid_github_signature?
        request.body.rewind

        token        = project.external_webhook_token
        payload_body = request.body.read
        signature    = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload_body)

        Rack::Utils.secure_compare(signature, github_webhook_signature)
      end

      def authenticate_with_webhook_token!
        if github_webhook_signature
          not_found! unless project

          authenticate_from_github_webhook!
        else
          authenticate!
          authorize_admin_project
        end
      end

      def project
        @project ||= github_webhook_signature ? find_project(params[:id]) : user_project
      end
    end

    params do
      requires :id, type: String, desc: 'The ID of a project'

      # pull_request params
      optional :action, type: String, desc: 'Pull Request action'
      optional 'pull_request.number', type: Integer, desc: 'Pull request IID'
      optional 'pull_request.head.ref', type: String, desc: 'Source branch'
      optional 'pull_request.head.sha', type: String, desc: 'Source sha'
      optional 'pull_request.head.repo.full_name', type: String, desc: 'Source repository'
      optional 'pull_request.base.ref', type: String, desc: 'Target branch'
      optional 'pull_request.base.sha', type: String, desc: 'Target sha'
      optional 'pull_request.base.repo.full_name', type: String, desc: 'Target repository'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Triggers a pull mirror operation'
      post ":id/mirror/pull" do
        authenticate_with_webhook_token!

        break render_api_error!('The project is not mirrored', 400) unless project.mirror?

        if params[:pull_request]
          if external_pull_request = ProcessGithubPullRequestEventService.new(project, current_user).execute(params)
            render_validation_error!(external_pull_request)
          else
            render_api_error!('The pull request event is not processable', 422)
          end
        else
          project.import_state.force_import_job!
        end

        status 200
      end
    end
  end
end
