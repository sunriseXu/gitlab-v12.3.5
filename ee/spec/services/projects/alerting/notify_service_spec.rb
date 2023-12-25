# frozen_string_literal: true

require 'spec_helper'

describe Projects::Alerting::NotifyService do
  set(:project) { create(:project) }

  before do
    # We use `set(:project)` so we make sure to clear caches
    project.clear_memoization(:licensed_feature_available)
  end

  shared_examples 'processes incident issues' do |amount|
    let(:create_incident_service) { spy }

    it 'processes issues', :sidekiq do
      expect(IncidentManagement::ProcessAlertWorker)
        .to receive(:perform_async)
        .with(project.id, kind_of(Hash))
        .exactly(amount).times

      Sidekiq::Testing.inline! do
        expect(subject.status).to eq(:success)
      end
    end
  end

  shared_examples 'does not process incident issues' do |http_status:|
    it 'does not process issues' do
      expect(IncidentManagement::ProcessAlertWorker)
        .not_to receive(:perform_async)

      expect(subject.status).to eq(:error)
      expect(subject.http_status).to eq(http_status)
    end
  end

  describe '#execute' do
    let(:token) { :development_token }
    let(:starts_at) { Time.now.change(usec: 0) }
    let(:service) { described_class.new(project, nil, payload) }
    let(:payload_raw) do
      {
        'title' => 'alert title',
        'start_time' => starts_at.rfc3339
      }
    end
    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }

    subject { service.execute(token) }

    context 'with license' do
      before do
        stub_licensed_features(incident_management: true)
      end

      context 'with Generic Alert Endpoint feature enabled' do
        before do
          stub_feature_flags(generic_alert_endpoint: true)
        end

        context 'with valid token' do
          it_behaves_like 'processes incident issues', 1
        end

        context 'with invalid token' do
          let(:token) { 'invalid-token' }

          it_behaves_like 'does not process incident issues', http_status: 401
        end
      end

      context 'with Generic Alert Endpoint feature disabled' do
        before do
          stub_feature_flags(generic_alert_endpoint: false)
        end

        it_behaves_like 'does not process incident issues', http_status: 403
      end
    end

    context 'without license' do
      before do
        stub_licensed_features(incident_management: false)
      end

      it_behaves_like 'does not process incident issues', http_status: 403
    end
  end
end
