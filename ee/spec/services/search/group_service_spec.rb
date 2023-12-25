require 'spec_helper'

describe Search::GroupService, :elastic do
  include SearchResultHelpers
  include ProjectHelpers
  using RSpec::Parameterized::TableSyntax

  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it_behaves_like 'EE search service shared examples', ::Gitlab::GroupSearchResults, ::Gitlab::Elastic::GroupSearchResults do
    let(:scope) { create(:group) }
    let(:service) { described_class.new(user, scope, search: '*') }
  end

  describe 'group search' do
    let(:term) { "Project Name" }
    let(:nested_group) { create(:group, :nested) }

    # These projects shouldn't be found
    let(:outside_project) { create(:project, :public, name: "Outside #{term}") }
    let(:private_project) { create(:project, :private, namespace: nested_group, name: "Private #{term}" )}
    let(:other_project)   { create(:project, :public, namespace: nested_group, name: term.reverse) }

    # These projects should be found
    let(:project1) { create(:project, :internal, namespace: nested_group, name: "Inner #{term} 1") }
    let(:project2) { create(:project, :internal, namespace: nested_group, name: "Inner #{term} 2") }
    let(:project3) { create(:project, :internal, namespace: nested_group.parent, name: "Outer #{term}") }

    let(:results) { described_class.new(user, search_group, search: term).execute }

    before do
      stub_ee_application_setting(
        elasticsearch_search: true,
        elasticsearch_indexing: true
      )

      # Ensure these are present when the index is refreshed
      _ = [
        outside_project, private_project, other_project,
        project1, project2, project3
      ]

      Gitlab::Elastic::Helper.refresh_index
    end

    context 'finding projects by name' do
      subject { results.objects('projects') }

      context 'in parent group' do
        let(:search_group) { nested_group.parent }

        it { is_expected.to match_array([project1, project2, project3]) }
      end

      context 'in subgroup' do
        let(:search_group) { nested_group }

        it { is_expected.to match_array([project1, project2]) }
      end
    end
  end

  context 'visibility' do
    include_context 'ProjectPolicyTable context'

    set(:group) { create(:group) }
    let!(:project) { create(:project, project_level, namespace: group) }
    let!(:project2) { create(:project, project_level) }
    let(:user) { create_user_from_membership(project, membership) }

    context 'merge request' do
      let!(:merge_request) { create :merge_request, target_project: project, source_project: project }
      let!(:merge_request2) { create :merge_request, target_project: project2, source_project: project2, title: merge_request.title }

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_reporter_feature_access
      end

      with_them do
        it "respects visibility" do
          [project, project2].each do |project|
            update_feature_access_level(project, feature_access_level)
          end
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'merge_requests', expected_count: expected_count) do |user|
            described_class.new(user, group, search: merge_request.title).execute
          end
        end
      end
    end

    context 'code' do
      let!(:project) { create(:project, project_level, :repository, namespace: group ) }

      where(:project_level, :feature_access_level, :membership, :expected_count) do
        permission_table_for_guest_feature_access
      end

      with_them do
        it "respects visibility" do
          [project, project2].each do |project|
            update_feature_access_level(project, feature_access_level)
            ElasticCommitIndexerWorker.new.perform(project.id)
          end
          ElasticCommitIndexerWorker.new.perform(project.id)
          Gitlab::Elastic::Helper.refresh_index

          expect_search_results(user, 'commits', expected_count: expected_count) do |user|
            described_class.new(user, group, search: 'initial').execute
          end

          expect_search_results(user, 'blobs', expected_count: expected_count) do |user|
            described_class.new(user, group, search: '.gitmodules').execute
          end
        end
      end
    end

    context 'project search' do
      let(:project) { create(:project, project_level, namespace: group) }

      where(:project_level, :membership, :expected_count) do
        permission_table_for_project_access
      end

      with_them do
        it "respects visibility" do
          ElasticCommitIndexerWorker.new.perform(project.id)
          Gitlab::Elastic::Helper.refresh_index

          expected_objects = expected_count == 1 ? [project] : []

          expect_search_results(
            user,
            'projects',
            expected_count: expected_count,
            expected_objects: expected_objects
          ) do |user|
            described_class.new(user, group, search: project.name).execute
          end
        end
      end
    end
  end
end
