# frozen_string_literal: true

require 'spec_helper'

describe Ci::Bridge do
  set(:project) { create(:project) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) do
    create(:ci_bridge, :variables, status: :created,
                                   options: options,
                                   pipeline: pipeline)
  end

  let(:options) do
    { trigger: { project: 'my/project', branch: 'master' } }
  end

  it 'belongs to an upstream pipeline' do
    expect(bridge).to belong_to(:upstream_pipeline)
  end

  it 'has many sourced pipelines' do
    expect(bridge).to have_many(:sourced_pipelines)
  end

  describe 'state machine transitions' do
    context 'when bridge points towards downstream' do
      it 'does not subscribe to upstream project' do
        expect(::Ci::SubscribeBridgeService).not_to receive(:new)

        bridge.enqueue!
      end

      it 'schedules downstream pipeline creation' do
        expect(bridge).to receive(:schedule_downstream_pipeline!)

        bridge.enqueue!
      end
    end

    context 'when bridge points towards upstream' do
      before do
        bridge.options = { bridge_needs: { pipeline: 'my/project' } }
      end

      it 'subscribes to the upstream project' do
        expect(::Ci::SubscribeBridgeService).to receive_message_chain(:new, :execute)

        bridge.enqueue!
      end

      it 'does not schedule downstream pipeline creation' do
        expect(bridge).not_to receive(:schedule_downstream_pipeline!)

        bridge.enqueue!
      end
    end
  end

  describe '#inherit_status_from_upstream!' do
    before do
      bridge.status = 'pending'
      bridge.upstream_pipeline = upstream_pipeline
    end

    subject { bridge.inherit_status_from_upstream! }

    context 'when bridge does not have upstream pipeline' do
      let(:upstream_pipeline) { nil }

      it { is_expected.to be false }
    end

    context 'when upstream pipeline has the same status as the bridge' do
      let(:upstream_pipeline) { build(:ci_pipeline, status: bridge.status) }

      it { is_expected.to be false }
    end

    context 'when status is not supported' do
      (::Ci::Pipeline::AVAILABLE_STATUSES - ::Ci::Pipeline.bridgeable_statuses).each do |status|
        context "when status is #{status}" do
          let(:upstream_pipeline) { build(:ci_pipeline, status: status) }

          it 'returns false' do
            expect(subject).to eq(false)
          end

          it 'does not change the bridge status' do
            expect { subject }.not_to change { bridge.status }.from('pending')
          end
        end
      end
    end

    context 'when status is supported' do
      ::Ci::Pipeline.bridgeable_statuses.each do |status|
        context "when status is #{status}" do
          let(:upstream_pipeline) { build(:ci_pipeline, status: status) }

          it 'inherits the upstream status' do
            expect { subject }.to change { bridge.status }.from('pending').to(status)
          end
        end
      end
    end
  end

  describe '#inherit_status_from_downstream!' do
    let(:downstream_pipeline) { build(:ci_pipeline, status: downstream_status) }

    before do
      bridge.status = 'pending'
      create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge)
    end

    subject { bridge.inherit_status_from_downstream!(downstream_pipeline) }

    context 'when status is not supported' do
      (::Ci::Pipeline::AVAILABLE_STATUSES - ::Ci::Pipeline::COMPLETED_STATUSES).map(&:to_s).each do |status|
        context "when status is #{status}" do
          let(:downstream_status) { status }

          it 'returns false' do
            expect(subject).to eq(false)
          end

          it 'does not change the bridge status' do
            expect { subject }.not_to change { bridge.status }.from('pending')
          end
        end
      end
    end

    context 'when status is supported' do
      using RSpec::Parameterized::TableSyntax

      where(:downstream_status, :upstream_status) do
        [
          %w[success success],
          *::Ci::Pipeline.completed_statuses.without(:success).map { |status| [status.to_s, 'failed'] }
        ]
      end

      with_them do
        it 'inherits the downstream status' do
          expect { subject }.to change { bridge.status }.from('pending').to(upstream_status)
        end
      end
    end
  end

  describe '#target_user' do
    it 'is the same as a user who created a pipeline' do
      expect(bridge.target_user).to eq bridge.user
    end
  end

  describe '#target_project_path' do
    context 'when trigger is defined' do
      it 'returns a full path of a project' do
        expect(bridge.target_project_path).to eq 'my/project'
      end
    end

    context 'when trigger does not have project defined' do
      let(:options) { { trigger: {} } }

      it 'returns nil' do
        expect(bridge.target_project_path).to be_nil
      end
    end
  end

  describe '#target_ref' do
    context 'when trigger is defined' do
      it 'returns a ref name' do
        expect(bridge.target_ref).to eq 'master'
      end
    end

    context 'when trigger does not have project defined' do
      let(:options) { nil }

      it 'returns nil' do
        expect(bridge.target_ref).to be_nil
      end
    end
  end

  describe '#dependent?' do
    subject { bridge.dependent? }

    context 'when bridge has strategy depend' do
      let(:options) { { trigger: { project: 'my/project', strategy: 'depend' } } }

      it { is_expected.to be true }
    end

    context 'when bridge does not have strategy depend' do
      it { is_expected.to be false }
    end
  end

  describe '#yaml_variables' do
    it 'returns YAML variables' do
      expect(bridge.yaml_variables)
        .to include(key: 'BRIDGE', value: 'cross', public: true)
    end
  end

  describe '#downstream_variables' do
    it 'returns variables that are going to be passed downstream' do
      expect(bridge.downstream_variables)
        .to include(key: 'BRIDGE', value: 'cross')
    end

    context 'when using variables interpolation' do
      before do
        bridge.yaml_variables << { key: 'EXPANDED', value: '$BRIDGE-bridge', public: true }
      end

      it 'correctly expands variables with interpolation' do
        expect(bridge.downstream_variables)
          .to include(key: 'EXPANDED', value: 'cross-bridge')
      end
    end

    context 'when recursive interpolation has been used' do
      before do
        bridge.yaml_variables << { key: 'EXPANDED', value: '$EXPANDED', public: true }
      end

      it 'does not expand variable recursively' do
        expect(bridge.downstream_variables)
          .to include(key: 'EXPANDED', value: '$EXPANDED')
      end
    end
  end

  describe 'metadata support' do
    it 'reads YAML variables from metadata' do
      expect(bridge.yaml_variables).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:yaml_variables)).to be_nil
      expect(bridge.metadata.config_variables).to be bridge.yaml_variables
    end

    it 'reads options from metadata' do
      expect(bridge.options).not_to be_empty
      expect(bridge.metadata).to be_a Ci::BuildMetadata
      expect(bridge.read_attribute(:options)).to be_nil
      expect(bridge.metadata.config_options).to be bridge.options
    end
  end
end
