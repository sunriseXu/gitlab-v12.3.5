# frozen_string_literal: true

require 'spec_helper'

describe Ci::WebIdeConfigService do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }
  let(:sha) { 'sha' }

  describe '#execute' do
    subject { described_class.new(project, user, sha: sha).execute }

    context 'when insufficient permission' do
      it 'returns an error' do
        is_expected.to include(
          status: :error,
          message: 'Insufficient permissions to read configuration')
      end
    end

    context 'for developer' do
      before do
        project.add_developer(user)
      end

      context 'when file is missing' do
        it 'returns an error' do
          is_expected.to include(
            status: :error,
            message: "Failed to load Web IDE config file '.gitlab/.gitlab-webide.yml' for sha")
        end
      end

      context 'when file is present' do
        before do
          allow(project.repository).to receive(:blob_data_at).with('sha', anything) do
            config_content
          end
        end

        context 'content is not valid' do
          let(:config_content) { 'invalid content' }

          it 'returns an error' do
            is_expected.to include(
              status: :error,
              message: "Invalid configuration format")
          end
        end

        context 'content is valid, but terminal not defined' do
          let(:config_content) { '{}' }

          it 'returns success' do
            is_expected.to include(
              status: :success,
              terminal: nil)
          end
        end

        context 'content is valid, with enabled terminal' do
          let(:config_content) { 'terminal: {}' }

          it 'returns success' do
            is_expected.to include(
              status: :success,
              terminal: {
                tag_list: [],
                yaml_variables: [],
                options: { script: ["sleep 60"] }
              })
          end
        end

        context 'content is valid, with custom terminal' do
          let(:config_content) { 'terminal: { before_script: [ls] }' }

          it 'returns success' do
            is_expected.to include(
              status: :success,
              terminal: {
                tag_list: [],
                yaml_variables: [],
                options: { before_script: ["ls"], script: ["sleep 60"] }
              })
          end
        end
      end
    end
  end
end
