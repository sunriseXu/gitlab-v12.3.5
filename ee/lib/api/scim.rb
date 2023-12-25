# frozen_string_literal: true

module API
  class Scim < Grape::API
    prefix 'api/scim'
    version 'v2'
    content_type :json, 'application/scim+json'
    USER_ID_REQUIREMENTS = { id: /.+/ }.freeze

    namespace 'groups/:group' do
      params do
        requires :group, type: String
      end

      helpers do
        def logger
          API.logger
        end

        def destroy_identity(identity)
          GroupSaml::Identity::DestroyService.new(identity).execute(transactional: true)

          true
        rescue => e
          logger.error(identity: identity, error: e.class.name, message: e.message, source: "#{__FILE__}:#{__LINE__}")

          false
        end

        def render_scim_error(error_class, message)
          error!({ with: error_class }.merge(detail: message), error_class::STATUS)
        end

        def scim_not_found!(message:)
          render_scim_error(EE::Gitlab::Scim::NotFound, message)
        end

        def scim_error!(message:)
          render_scim_error(EE::Gitlab::Scim::Error, message)
        end

        def scim_conflict!(message:)
          render_scim_error(EE::Gitlab::Scim::Conflict, message)
        end

        def find_and_authenticate_group!(group_path)
          group = find_group(group_path)

          scim_not_found!(message: "Group #{group_path} not found") unless group

          token = Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
          unauthorized! unless token

          scim_token = ScimOauthAccessToken.token_matches_for_group?(token, group)
          unauthorized! unless scim_token

          group
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def update_scim_user(identity)
          parser = EE::Gitlab::Scim::ParamsParser.new(params)
          parsed_hash = parser.result

          if parser.deprovision_user?
            destroy_identity(identity)
          elsif parsed_hash[:extern_uid]
            identity.update(parsed_hash.slice(:extern_uid))
          else
            scim_conflict!(message: 'Email has already been taken') if email_taken?(parsed_hash[:email], identity)

            result = ::Users::UpdateService.new(identity.user,
                                                parsed_hash.except(:extern_uid)
                                                  .merge(user: identity.user)).execute

            result[:status] == :success
          end
        end

        def email_taken?(email, identity)
          return unless email

          User.by_any_email(email.downcase).where.not(id: identity.user.id).exists?
        end
      end

      resource :Users do
        before do
          check_group_scim_enabled(find_group(params[:group]))
          check_group_saml_configured
        end

        desc 'Get SAML users' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        get do
          scim_error!(message: 'Missing filter params') unless params[:filter]

          group = find_and_authenticate_group!(params[:group])
          parsed_hash = EE::Gitlab::Scim::ParamsParser.new(params).result
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: parsed_hash[:extern_uid])

          status 200

          present identity || {}, with: ::EE::Gitlab::Scim::Users
        end

        desc 'Get a SAML user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        get ':id', requirements: USER_ID_REQUIREMENTS do
          group = find_and_authenticate_group!(params[:group])

          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          status 200

          present identity, with: ::EE::Gitlab::Scim::User
        end

        desc 'Create a SAML user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        post do
          group = find_and_authenticate_group!(params[:group])
          parser = EE::Gitlab::Scim::ParamsParser.new(params)
          result = EE::Gitlab::Scim::ProvisioningService.new(group, parser.result).execute

          case result.status
          when :success
            status 201

            present result.identity, with: ::EE::Gitlab::Scim::User
          when :conflict
            scim_conflict!(message: "Error saving user with #{params.inspect}: #{result.message}")
          when :error
            scim_error!(message: ["Error saving user with #{params.inspect}", result.message].compact.join(": "))
          end
        end

        desc 'Updates a SAML user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        patch ':id', requirements: USER_ID_REQUIREMENTS do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_and_authenticate_group!(params[:group])
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          updated = update_scim_user(identity)

          if updated
            status 204

            {}
          else
            scim_error!(message: "Error updating #{identity.user.name} with #{params.inspect}")
          end
        end

        desc 'Removes a SAML user' do
          detail 'This feature was introduced in GitLab 11.10.'
        end
        delete ':id', requirements: USER_ID_REQUIREMENTS do
          scim_error!(message: 'Missing ID') unless params[:id]

          group = find_and_authenticate_group!(params[:group])
          identity = GroupSamlIdentityFinder.find_by_group_and_uid(group: group, uid: params[:id])

          scim_not_found!(message: "Resource #{params[:id]} not found") unless identity

          destroyed = destroy_identity(identity)

          scim_not_found!(message: "Resource #{params[:id]} not found") unless destroyed

          status 204

          {}
        end
      end
    end
  end
end
