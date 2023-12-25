# frozen_string_literal: true

require 'spec_helper'

describe Projects::FeatureFlagsClientsController do
  include Gitlab::Routing

  set(:project) { create(:project) }
  set(:user) { create(:user) }

  describe 'POST reset_token.json' do
    subject(:reset_token) do
      post :reset_token,
        params: { namespace_id: project.namespace, project_id: project },
        format: :json
    end

    before do
      stub_licensed_features(feature_flags: true)
      sign_in(user)
    end

    context 'when user is a project maintainer' do
      before do
        project.add_maintainer(user)
      end

      context 'and feature flags client exist' do
        it 'regenerates feature flags client token' do
          project.create_operations_feature_flags_client!
          expect { reset_token }.to change { project.reload.feature_flags_client_token }

          expect(json_response['token']).to eq(project.feature_flags_client_token)
        end
      end

      context 'but feature flags client does not exist' do
        it 'returns 404' do
          reset_token

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when user is not a project maintainer' do
      before do
        project.add_developer(user)
      end

      it 'returns 404' do
        reset_token

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end
end
