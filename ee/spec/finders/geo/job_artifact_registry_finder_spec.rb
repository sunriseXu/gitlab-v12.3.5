require 'spec_helper'

describe Geo::JobArtifactRegistryFinder, :geo_fdw do
  include ::EE::GeoHelpers

  # Using let() instead of set() because set() does not work properly
  # when using the :delete DatabaseCleaner strategy, which is required for FDW
  # tests because a foreign table can't see changes inside a transaction of a
  # different connection.
  let(:secondary) { create(:geo_node) }
  let(:synced_group) { create(:group) }
  let(:synced_project) { create(:project, group: synced_group) }
  let(:unsynced_project) { create(:project) }
  let(:project_broken_storage) { create(:project, :broken_storage) }

  subject { described_class.new(current_node_id: secondary.id) }

  before do
    stub_current_geo_node(secondary)
    stub_artifacts_object_storage
  end

  let!(:job_artifact_synced_project) { create(:ci_job_artifact, project: synced_project) }
  let!(:job_artifact_unsynced_project) { create(:ci_job_artifact, project: unsynced_project) }
  let!(:job_artifact_broken_storage_1) { create(:ci_job_artifact, project: project_broken_storage) }
  let!(:job_artifact_broken_storage_2) { create(:ci_job_artifact, project: project_broken_storage) }
  let!(:job_artifact_expired_synced_project) { create(:ci_job_artifact, :expired, project: synced_project) }
  let!(:job_artifact_expired_broken_storage) { create(:ci_job_artifact, :expired, project: project_broken_storage) }
  let!(:job_artifact_remote_synced_project) { create(:ci_job_artifact, :remote_store, project: synced_project) }
  let!(:job_artifact_remote_unsynced_project) { create(:ci_job_artifact, :remote_store, project: unsynced_project) }
  let!(:job_artifact_remote_broken_storage) { create(:ci_job_artifact, :expired, :remote_store, project: project_broken_storage) }

  context 'counts all the things' do
    describe '#count_syncable' do
      it 'counts non-expired job artifacts' do
        expect(subject.count_syncable).to eq 6
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts non-expired job artifacts' do
          expect(subject.count_syncable).to eq 2
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts non-expired job artifacts' do
          expect(subject.count_syncable).to eq 2
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts non-expired job artifacts' do
          expect(subject.count_syncable).to eq 4
        end
      end
    end

    describe '#count_synced' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_unsynced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_2.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_synced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id)
      end

      context 'without selective sync' do
        it 'counts job artifacts that have been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 3
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts job artifacts that has been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 1
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts job artifacts that has been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts job artifacts that has been synced ignoring expired job artifacts' do
          expect(subject.count_synced).to eq 2
        end
      end
    end

    describe '#count_failed' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_unsynced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_broken_storage.id, success: false)
      end

      context 'without selective sync' do
        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 3
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 2
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts job artifacts that sync has failed ignoring expired ones' do
          expect(subject.count_failed).to eq 2
        end
      end
    end

    describe '#count_synced_missing_on_primary' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false, missing_on_primary: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_unsynced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_synced_project.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_unsynced_project.id, missing_on_primary: false)
      end

      context 'without selective sync' do
        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 2
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts job artifacts that have been synced and are missing on the primary, ignoring expired ones' do
          expect(subject.count_synced_missing_on_primary).to eq 1
        end
      end
    end

    describe '#count_registry' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_2.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id, missing_on_primary: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_unsynced_project.id)
      end

      it 'counts file registries for job artifacts' do
        expect(subject.count_registry).to eq 4
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 4
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'does not apply the selective sync restriction' do
          expect(subject.count_registry).to eq 4
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'counts file registries for job artifacts ignoring remote artifacts' do
          expect(subject.count_registry).to eq 4
        end
      end
    end
  end

  context 'finds all the things' do
    describe '#find_unsynced' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id, success: false)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_broken_storage_1.id, success: true)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_expired_broken_storage.id, success: true)
      end

      context 'without selective sync' do
        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10, except_artifact_ids: [job_artifact_unsynced_project.id])

          expect(job_artifacts).to match_ids(job_artifact_remote_synced_project, job_artifact_remote_unsynced_project,
                                             job_artifact_broken_storage_2)
        end
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_synced_project)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_broken_storage_2)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'returns job artifacts without an entry on the tracking database, ignoring expired ones and remotes' do
          job_artifacts = subject.find_unsynced(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_unsynced_project, job_artifact_broken_storage_2)
        end
      end
    end

    describe '#find_migrated_local' do
      before do
        create(:geo_job_artifact_registry, artifact_id: job_artifact_synced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_synced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_unsynced_project.id)
        create(:geo_job_artifact_registry, artifact_id: job_artifact_remote_broken_storage.id)
      end

      it 'returns job artifacts excluding ones from the exception list' do
        job_artifacts = subject.find_migrated_local(batch_size: 10, except_artifact_ids: [job_artifact_remote_synced_project.id])

        expect(job_artifacts).to match_ids(job_artifact_remote_unsynced_project, job_artifact_remote_broken_storage)
      end

      it 'includes synced job artifacts that are expired, exclude stored locally' do
        job_artifacts = subject.find_migrated_local(batch_size: 10)

        expect(job_artifacts).to match_ids(job_artifact_remote_synced_project, job_artifact_remote_unsynced_project,
                                           job_artifact_remote_broken_storage)
      end

      context 'with selective sync by namespace' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [synced_group]) }

        it 'returns job artifacts remotely and successfully synced locally' do
          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_synced_project)
        end
      end

      context 'with selective sync by shard' do
        let(:secondary) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['broken']) }

        it 'returns job artifacts remotely and successfully synced locally' do
          job_artifacts = subject.find_migrated_local(batch_size: 10)

          expect(job_artifacts).to match_ids(job_artifact_remote_broken_storage)
        end
      end

      context 'with object storage sync disabled' do
        let(:secondary) { create(:geo_node, :local_storage_only) }

        it 'returns job artifacts excluding ones from the exception list' do
          job_artifacts = subject.find_migrated_local(batch_size: 10, except_artifact_ids: [job_artifact_remote_synced_project.id])

          expect(job_artifacts).to match_ids(job_artifact_remote_unsynced_project, job_artifact_remote_broken_storage)
        end
      end
    end
  end

  it_behaves_like 'a file registry finder'
end
