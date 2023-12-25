# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::VersionsFinder do
  include DesignManagementTestHelpers

  set(:user) { create(:user) }
  set(:project) { create(:project, :private) }
  set(:issue) { create(:issue, project: project) }
  set(:design_1) { create(:design, :with_file, issue: issue, versions_count: 1) }
  set(:design_2) { create(:design, :with_file, issue: issue, versions_count: 1) }
  let(:version_1) { design_1.versions.first }
  let(:version_2) { design_2.versions.first }
  let(:design_or_collection) { issue.design_collection }
  let(:params) { {} }

  subject(:versions) { described_class.new(design_or_collection, user, params).execute }

  describe '#execute' do
    shared_examples 'returns no results' do
      it 'returns no results when passed a DesignCollection' do
        expect(design_or_collection).is_a?(DesignManagement::DesignCollection)
        is_expected.to be_empty
      end

      context 'when passed a Design' do
        let(:design_or_collection) { design_1 }

        it 'returns no results when passed a Design' do
          is_expected.to be_empty
        end
      end
    end

    context 'when user cannot read designs of an issue' do
      include_examples 'returns no results'
    end

    context 'when user can read designs of an issue' do
      before do
        project.add_developer(user)
      end

      context 'when design management feature is disabled' do
        include_examples 'returns no results'
      end

      context 'when design management feature is enabled' do
        before do
          enable_design_management
        end

        describe 'passing a DesignCollection or a Design for the initial scoping' do
          it 'returns the versions scoped to the DesignCollection' do
            expect(design_or_collection).is_a?(DesignManagement::DesignCollection)
            is_expected.to eq(issue.design_collection.versions.ordered)
          end

          context 'when passed a Design' do
            let(:design_or_collection) { design_1 }

            it 'returns the versions scoped to the Design' do
              is_expected.to eq(design_1.versions)
            end
          end
        end

        describe 'returning versions earlier or equal to a version' do
          context 'when argument is the first version' do
            let(:params) { { earlier_or_equal_to: version_1 }}

            it { is_expected.to eq([version_1]) }
          end

          context 'when argument is the second version' do
            let(:params) { { earlier_or_equal_to: version_2 }}

            it { is_expected.to contain_exactly(version_1, version_2) }
          end
        end
      end
    end
  end
end
