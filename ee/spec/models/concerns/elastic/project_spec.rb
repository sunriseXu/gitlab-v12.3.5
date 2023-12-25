# frozen_string_literal: true

require 'spec_helper'

describe Project, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  context 'when limited indexing is on' do
    set(:project) { create :project, name: 'test1' }

    before do
      stub_ee_application_setting(elasticsearch_limit_indexing: true)
    end

    context 'when the project is not enabled specifically' do
      context '#searchable?' do
        it 'returns false' do
          expect(project.searchable?).to be_falsey
        end
      end

      context '#use_elasticsearch?' do
        it 'returns false' do
          expect(project.use_elasticsearch?).to be_falsey
        end
      end
    end

    context 'when a project is enabled specifically' do
      before do
        create :elasticsearch_indexed_project, project: project
      end

      context '#searchable?' do
        it 'returns true' do
          expect(project.searchable?).to be_truthy
        end
      end

      context '#use_elasticsearch?' do
        it 'returns true' do
          expect(project.use_elasticsearch?).to be_truthy
        end
      end

      it 'only indexes enabled projects' do
        Sidekiq::Testing.inline! do
          # We have to trigger indexing of the previously-created project because we don't have a way to
          # enable ES for it before it's created, at which point it won't be indexed anymore
          ElasticIndexerWorker.perform_async(:index, project.class.to_s, project.id, project.es_id)
          create :project, path: 'test2', description: 'awesome project'
          create :project

          Gitlab::Elastic::Helper.refresh_index
        end

        expect(described_class.elastic_search('test*', options: { project_ids: :any }).total_count).to eq(1)
        expect(described_class.elastic_search('test2', options: { project_ids: :any }).total_count).to eq(0)
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

          expect(project.searchable?).to be_truthy
        end
      end

      it 'indexes only projects under the group' do
        Sidekiq::Testing.inline! do
          create :project, name: 'test1', group: create(:group, parent: group)
          create :project, name: 'test2', description: 'awesome project'
          create :project, name: 'test3', group: group
          create :project, path: 'someone_elses_project', name: 'test4'

          Gitlab::Elastic::Helper.refresh_index
        end

        expect(described_class.elastic_search('test*', options: { project_ids: :any }).total_count).to eq(2)
        expect(described_class.elastic_search('test3', options: { project_ids: :any }).total_count).to eq(1)
        expect(described_class.elastic_search('test2', options: { project_ids: :any }).total_count).to eq(0)
        expect(described_class.elastic_search('test4', options: { project_ids: :any }).total_count).to eq(0)
      end
    end
  end

  it "finds projects" do
    project_ids = []

    Sidekiq::Testing.inline! do
      project = create :project, name: 'test1'
      project1 = create :project, path: 'test2', description: 'awesome project'
      project2 = create :project
      create :project, path: 'someone_elses_project'
      project_ids += [project.id, project1.id, project2.id]

      # The project you have no access to except as an administrator
      create :project, :private, name: 'test3'

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(described_class.elastic_search('test1', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('test2', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('awesome', options: { project_ids: project_ids }).total_count).to eq(1)
    expect(described_class.elastic_search('test*', options: { project_ids: project_ids }).total_count).to eq(2)
    expect(described_class.elastic_search('test*', options: { project_ids: :any }).total_count).to eq(3)
    expect(described_class.elastic_search('someone_elses_project', options: { project_ids: project_ids }).total_count).to eq(0)
  end

  it "finds partial matches in project names" do
    project_ids = []

    Sidekiq::Testing.inline! do
      project = create :project, name: 'tesla-model-s'
      project1 = create :project, name: 'tesla_model_s'
      project_ids += [project.id, project1.id]

      Gitlab::Elastic::Helper.refresh_index
    end

    expect(described_class.elastic_search('tesla', options: { project_ids: project_ids }).total_count).to eq(2)
  end

  it "returns json with all needed elements" do
    project = create :project

    expected_hash = project.attributes.extract!(
      'id',
      'name',
      'path',
      'description',
      'namespace_id',
      'created_at',
      'archived',
      'updated_at',
      'visibility_level',
      'last_activity_at'
    ).merge({ 'join_field' => project.es_type, 'type' => project.es_type })

    expected_hash.merge!(
      project.project_feature.attributes.extract!(
        'issues_access_level',
        'merge_requests_access_level',
        'snippets_access_level',
        'wiki_access_level',
        'repository_access_level'
      )
    )

    expected_hash['name_with_namespace'] = project.full_name
    expected_hash['path_with_namespace'] = project.full_path

    expect(project.__elasticsearch__.as_indexed_json).to eq(expected_hash)
  end
end
