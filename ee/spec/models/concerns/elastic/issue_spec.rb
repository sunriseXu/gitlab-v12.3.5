# frozen_string_literal: true

require 'spec_helper'

describe Issue, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  let(:project) { create :project, :public }
  let(:admin) { create :user, :admin }

  context 'when limited indexing is on' do
    set(:project) { create :project, name: 'test1' }
    set(:issue) { create :issue, project: project}

    before do
      stub_ee_application_setting(elasticsearch_limit_indexing: true)
    end

    context 'when the project is not enabled specifically' do
      context '#searchable?' do
        it 'returns false' do
          expect(issue.searchable?).to be_falsey
        end
      end
    end

    context 'when a project is enabled specifically' do
      before do
        create :elasticsearch_indexed_project, project: project
      end

      context '#searchable?' do
        it 'returns true' do
          expect(issue.searchable?).to be_truthy
        end
      end
    end

    context 'when a group is enabled' do
      set(:group) { create(:group) }

      before do
        create :elasticsearch_indexed_namespace, namespace: group
      end

      context '#searchable?' do
        it 'returns true' do
          project = create :project, name: 'test1', group: group
          issue = create :issue, project: project

          expect(issue.searchable?).to be_truthy
        end
      end
    end
  end

  it "searches issues" do
    Sidekiq::Testing.inline! do
      create :issue, title: 'bla-bla term1', project: project
      create :issue, description: 'bla-bla term2', project: project
      create :issue, project: project

      # The issue I have no access to except as an administrator
      create :issue, title: 'bla-bla term3', project: create(:project, :private)

      Gitlab::Elastic::Helper.refresh_index
    end

    options = { project_ids: [project.id] }

    expect(described_class.elastic_search('(term1 | term2 | term3) +bla-bla', options: options).total_count).to eq(2)
    expect(described_class.elastic_search(Issue.last.to_reference, options: options).total_count).to eq(1)
    expect(described_class.elastic_search('bla-bla', options: { project_ids: :any, public_and_internal_projects: true }).total_count).to eq(3)
  end

  it "searches by iid and scopes to type: issue only" do
    issue = nil

    Sidekiq::Testing.inline! do
      issue = create :issue, title: 'bla-bla issue', project: project
      create :issue, description: 'term2 in description', project: project

      # MergeRequest with the same iid should not be found in Issue search
      create :merge_request, title: 'bla-bla', source_project: project, iid: issue.iid

      Gitlab::Elastic::Helper.refresh_index
    end

    # User needs to be admin or the MergeRequest would just be filtered by
    # confidential: false
    options = { project_ids: [project.id], current_user: admin }

    results = described_class.elastic_search("##{issue.iid}", options: options)
    expect(results.total_count).to eq(1)
    expect(results.first.title).to eq('bla-bla issue')
  end

  it "returns json with all needed elements" do
    assignee = create(:user)
    issue = create :issue, project: project, assignees: [assignee]

    expected_hash = issue.attributes.extract!('id', 'iid', 'title', 'description', 'created_at',
                                                'updated_at', 'state', 'project_id', 'author_id',
                                                'confidential')
                                    .merge({
                                            'join_field' => {
                                              'name' => issue.es_type,
                                              'parent' => issue.es_parent
                                            },
                                            'type' => issue.es_type
                                           })

    expected_hash['assignee_id'] = [assignee.id]

    expect(issue.__elasticsearch__.as_indexed_json).to eq(expected_hash)
  end

  it_behaves_like 'no results when the user cannot read cross project' do
    let(:record1) { create(:issue, project: project, title: 'test-issue') }
    let(:record2) { create(:issue, project: project2, title: 'test-issue') }
  end
end
