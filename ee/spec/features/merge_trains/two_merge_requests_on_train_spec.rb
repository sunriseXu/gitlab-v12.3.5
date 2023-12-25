# frozen_string_literal: true

require 'spec_helper'

describe 'Two merge requests on a merge train' do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
  set(:maintainer_1) { create(:user) }
  set(:maintainer_2) { create(:user) }

  let(:merge_request_1) do
    create(:merge_request,
      source_branch: 'feature', source_project: project,
      target_branch: 'master', target_project: project,
      merge_status: 'unchecked')
  end

  let(:merge_request_2) do
    create(:merge_request,
      source_branch: 'signed-commits', source_project: project,
      target_branch: 'master', target_project: project,
      merge_status: 'unchecked')
  end

  let(:ci_yaml) do
    { test: { stage: 'test', script: 'echo', only: ['merge_requests'] } }
  end

  before do
    project.add_maintainer(maintainer_1)
    project.add_maintainer(maintainer_2)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
    project.update!(merge_pipelines_enabled: true)
    stub_ci_pipeline_yaml_file(YAML.dump(ci_yaml))

    head_pipeline = double('Ci::Pipeline')
    allow(head_pipeline).to receive(:complete?) { true }
    allow(merge_request_1).to receive(:actual_head_pipeline) { head_pipeline }
    allow(merge_request_2).to receive(:actual_head_pipeline) { head_pipeline }

    AutoMergeService.new(project, maintainer_1)
      .execute(merge_request_1, AutoMergeService::STRATEGY_MERGE_TRAIN)
    AutoMergeService.new(project, maintainer_2)
      .execute(merge_request_2, AutoMergeService::STRATEGY_MERGE_TRAIN)

    merge_request_1.reload
    merge_request_2.reload
  end

  it 'creates a pipeline for merge request 1' do
    expect(merge_request_1.merge_train.pipeline).to be_merge_request_pipeline
    expect(merge_request_1.merge_train.pipeline.user).to eq(maintainer_1)
    expect(merge_request_1.merge_train.pipeline.ref).to eq(merge_request_1.train_ref_path)
    expect(merge_request_1.merge_train.pipeline.target_sha)
      .to eq(project.repository.commit('refs/heads/master').sha)
  end

  it 'creates a pipeline for merge request 2' do
    expect(merge_request_2.merge_train.pipeline).to be_merge_request_pipeline
    expect(merge_request_2.merge_train.pipeline.user).to eq(maintainer_2)
    expect(merge_request_2.merge_train.pipeline.ref).to eq(merge_request_2.train_ref_path)
    expect(merge_request_2.merge_train.pipeline.target_sha)
      .to eq(project.repository.commit(merge_request_1.train_ref_path).sha)
  end

  it 'does not merge anything yet' do
    expect(merge_request_1).to be_opened
    expect(merge_request_2).to be_opened
  end

  shared_examples_for 'drops merge request 1 from the merge train' do
    it 'drops merge request 1 from the merge train' do
      expect(merge_request_1).to be_opened
      expect(merge_request_1.merge_train).to be_nil
      expect(merge_request_1.notes.last.note).to eq(system_note)
    end
  end

  shared_examples_for 'has an intact pipeline for merge request 2' do
    it 'does not create a new pipeline for merge request 2' do
      expect(merge_request_2.all_pipelines.count).to eq(1)
    end

    context 'when the pipeline for merge request 2 succeeded' do
      before do
        merge_request_2.merge_train.pipeline.succeed!

        merge_request_2.reload
      end

      it 'merges merge request 2' do
        expect(merge_request_2).to be_merged
        expect(merge_request_2.metrics.merged_by).to eq(maintainer_2)
        expect(merge_request_2.merge_train).to be_nil
      end
    end
  end

  shared_examples_for 're-creates a pipeline for merge request 2' do
    it 'has recreated pipeline' do
      expect(merge_request_2.all_pipelines.count).to eq(2)
      expect(merge_request_2.merge_train.pipeline.target_sha)
        .to eq(target_branch_sha)
    end

    context 'when the pipeline for merge request 2 succeeded' do
      before do
        merge_request_2.merge_train.pipeline.succeed!

        merge_request_2.reload
      end

      it 'merges merge request 2' do
        expect(merge_request_2).to be_merged
        expect(merge_request_2.metrics.merged_by).to eq(maintainer_2)
        expect(merge_request_2.merge_train).to be_nil
      end
    end
  end

  context 'when the pipeline for merge request 1 succeeded' do
    before do
      merge_request_1.merge_train.pipeline.succeed!

      merge_request_1.reload
      merge_request_2.reload
    end

    it 'merges merge request 1' do
      expect(merge_request_1).to be_merged
      expect(merge_request_1.metrics.merged_by).to eq(maintainer_1)
      expect(merge_request_1.merge_train).to be_nil
    end

    it_behaves_like 'has an intact pipeline for merge request 2'
  end

  context 'when the pipeline for merge request 1 failed' do
    before do
      merge_request_1.merge_train.pipeline.drop!

      merge_request_1.reload
      merge_request_2.reload
    end

    it_behaves_like 'drops merge request 1 from the merge train' do
      let(:system_note) do
        'removed this merge request from the merge train because pipeline did not succeed'
      end
    end

    it_behaves_like 're-creates a pipeline for merge request 2' do
      let(:target_branch_sha) { project.repository.commit('refs/heads/master').sha }
    end
  end

  context 'when merge request 1 is canceled by a user' do
    before do
      AutoMergeService.new(project, maintainer_1).cancel(merge_request_1)

      merge_request_1.reload
      merge_request_2.reload
    end

    it_behaves_like 'drops merge request 1 from the merge train' do
      let(:system_note) do
        'removed this merge request from the merge train'
      end
    end

    it_behaves_like 're-creates a pipeline for merge request 2' do
      let(:target_branch_sha) { project.repository.commit('refs/heads/master').sha }
    end
  end

  context 'when merge request 1 is not mergeable' do
    before do
      merge_request_1.update!(title: merge_request_1.wip_title)
      merge_request_1.merge_train.pipeline.succeed!

      merge_request_1.reload
      merge_request_2.reload
    end

    it_behaves_like 'drops merge request 1 from the merge train' do
      let(:system_note) do
        'removed this merge request from the merge train because merge request is not mergeable'
      end
    end

    it_behaves_like 're-creates a pipeline for merge request 2' do
      let(:target_branch_sha) { project.repository.commit('refs/heads/master').sha }
    end
  end

  context 'when master got a new commit and pipeline for merge request 1 finished' do
    before do
      create_file_in_repo(project, 'master', 'master', 'test.txt', 'This is test')

      merge_request_1.merge_train.pipeline.succeed!
      merge_request_1.reload
      merge_request_2.reload
    end

    it 're-creates a pipeline for merge request 1' do
      expect(merge_request_1.all_pipelines.count).to eq(2)
      expect(merge_request_1.merge_train.pipeline.target_sha)
        .to eq(merge_request_1.target_branch_sha)
    end

    it 're-creates a pipeline for merge request 2' do
      expect(merge_request_2.all_pipelines.count).to eq(2)
      expect(merge_request_2.merge_train.pipeline.target_sha)
        .to eq(project.repository.commit(merge_request_1.train_ref_path).sha)
    end

    context 'when the pipeline for merge request 1 succeeded' do
      before do
        merge_request_1.merge_train.pipeline.succeed!

        merge_request_1.reload
      end

      it 'merges merge request 1' do
        expect(merge_request_1).to be_merged
        expect(merge_request_1.metrics.merged_by).to eq(maintainer_1)
      end

      context 'when the pipeline for merge request 2 succeeded' do
        before do
          merge_request_2.merge_train.pipeline.succeed!

          merge_request_2.reload
        end

        it 'merges merge request 2' do
          expect(merge_request_2).to be_merged
          expect(merge_request_2.metrics.merged_by).to eq(maintainer_2)
        end
      end
    end
  end
end
