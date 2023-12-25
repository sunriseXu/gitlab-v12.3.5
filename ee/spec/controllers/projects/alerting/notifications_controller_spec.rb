# frozen_string_literal: true

require 'spec_helper'

describe Projects::Alerting::NotificationsController do
  set(:project) { create(:project) }
  set(:environment) { create(:environment, project: project) }

  describe 'POST #create' do
    let(:service_response) { ServiceResponse.success }
    let(:notify_service) { instance_double(Projects::Alerting::NotifyService, execute: service_response) }

    before do
      allow(Projects::Alerting::NotifyService).to receive(:new).and_return(notify_service)
    end

    def make_request(opts = {})
      post :create, params: project_params(opts), session: { as: :json }
    end

    context 'when feature flag is on' do
      before do
        stub_feature_flags(generic_alert_endpoint: true)
      end

      context 'when notification service succeeds' do
        let(:payload) do
          {
            title: 'Alert title',
            hosts: 'https://gitlab.com'
          }
        end

        let(:permitted_params) { ActionController::Parameters.new(payload).permit! }

        it 'responds with ok' do
          make_request

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'does not pass excluded parameters to the notify service' do
          make_request(payload)

          expect(Projects::Alerting::NotifyService)
            .to have_received(:new)
            .with(project, nil, permitted_params)
        end
      end

      context 'when notification service fails' do
        let(:service_response) { ServiceResponse.error(message: 'Unauthorized', http_status: 401) }

        it 'responds with the service response' do
          make_request

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'bearer token' do
        context 'when set' do
          it 'extracts bearer token' do
            request.headers['HTTP_AUTHORIZATION'] = 'Bearer some token'

            expect(notify_service).to receive(:execute).with('some token')

            make_request
          end

          it 'pass nil if cannot extract a non-bearer token' do
            request.headers['HTTP_AUTHORIZATION'] = 'some token'

            expect(notify_service).to receive(:execute).with(nil)

            make_request
          end
        end

        context 'when missing' do
          it 'passes nil' do
            expect(notify_service).to receive(:execute).with(nil)

            make_request
          end
        end
      end
    end

    context 'when feature flag is off' do
      before do
        stub_feature_flags(generic_alert_endpoint: false)
      end

      it 'responds with not_found' do
        make_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  def project_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project)
  end
end
