# frozen_string_literal: true

require 'spec_helper'

describe Projects::ServiceDeskController do
  let(:project) { create(:project_empty_repo, :private, service_desk_enabled: true) }
  let(:user)    { create(:user) }

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:service_desk) { true }
    allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET service desk properties' do
    it 'returns service_desk JSON data' do
      get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

      expect(json_response["service_desk_address"]).to match(/\A[^@]+@[^@]+\z/)
      expect(json_response["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end

    context 'when user is not project maintainer' do
      let(:guest) { create(:user) }

      it 'renders 404' do
        project.add_guest(guest)
        sign_in(guest)

        get :show, params: { namespace_id: project.namespace.to_param, project_id: project }, format: :json

        expect(response.status).to eq(404)
      end
    end
  end

  describe 'PUT service desk properties' do
    it 'toggles services desk incoming email' do
      project.update!(service_desk_enabled: false)

      put :update, params: { namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true }, format: :json

      expect(json_response["service_desk_address"]).to be_present
      expect(json_response["service_desk_enabled"]).to be_truthy
      expect(response.status).to eq(200)
    end

    context 'when user cannot admin the project' do
      let(:other_user) { create(:user) }

      it 'renders 404' do
        sign_in(other_user)
        put :update, params: { namespace_id: project.namespace.to_param, project_id: project, service_desk_enabled: true }, format: :json

        expect(response.status).to eq(404)
      end
    end
  end
end
