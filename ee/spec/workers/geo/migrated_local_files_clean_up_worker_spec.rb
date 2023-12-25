require 'spec_helper'

describe Geo::MigratedLocalFilesCleanUpWorker, :geo, :geo_fdw do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let(:primary)   { create(:geo_node, :primary, host: 'primary-geo-node') }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)
  end

  it 'does not run when node is disabled' do
    secondary.update_column(:enabled, false)

    expect(subject).not_to receive(:try_obtain_lease)

    subject.perform
  end

  context 'with LFS objects' do
    let(:lfs_object_local) { create(:lfs_object) }
    let(:lfs_object_remote) { create(:lfs_object, :object_storage) }

    before do
      stub_lfs_object_storage

      create(:geo_file_registry, :lfs, file_id: lfs_object_local.id)
      create(:geo_file_registry, :lfs, file_id: lfs_object_remote.id)
    end

    it 'schedules job for file stored remotely and synced locally' do
      expect(subject).to receive(:schedule_job).with('lfs', lfs_object_remote.id)
      expect(subject).not_to receive(:schedule_job).with(anything, lfs_object_local.id)

      subject.perform
    end

    it 'schedules worker for file stored remotely and synced locally' do
      expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('lfs', lfs_object_remote.id)
      expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with(anything, lfs_object_local.id)

      subject.perform
    end
  end

  context 'with attachments' do
    let(:avatar_upload) { create(:upload) }
    let(:personal_snippet_upload) { create(:upload, :personal_snippet_upload) }
    let(:issuable_upload) { create(:upload, :issuable_upload) }
    let(:namespace_upload) { create(:upload, :namespace_upload) }
    let(:attachment_upload) { create(:upload, :attachment_upload) }
    let(:favicon_upload) { create(:upload, :favicon_upload) }

    before do
      create(:geo_file_registry, :avatar, file_id: avatar_upload.id)
      create(:geo_file_registry, :personal_file, file_id: personal_snippet_upload.id)
      create(:geo_file_registry, :file, file_id: issuable_upload.id)
      create(:geo_file_registry, :namespace_file, file_id: namespace_upload.id)
      create(:geo_file_registry, :attachment, file_id: attachment_upload.id)
      create(:geo_file_registry, :favicon, file_id: favicon_upload.id)
    end

    it 'schedules nothing for attachments stored locally' do
      expect(subject).not_to receive(:schedule_job).with(anything, avatar_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, personal_snippet_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, issuable_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, namespace_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, attachment_upload.id)
      expect(subject).not_to receive(:schedule_job).with(anything, favicon_upload.id)

      subject.perform
    end

    context 'attachments stored remotely' do
      before do
        stub_uploads_object_storage(AvatarUploader)
        stub_uploads_object_storage(PersonalFileUploader)
        stub_uploads_object_storage(FileUploader)
        stub_uploads_object_storage(NamespaceFileUploader)
        stub_uploads_object_storage(AttachmentUploader)
        stub_uploads_object_storage(FaviconUploader)

        avatar_upload.update_column(:store, FileUploader::Store::REMOTE)
        personal_snippet_upload.update_column(:store, FileUploader::Store::REMOTE)
        issuable_upload.update_column(:store, FileUploader::Store::REMOTE)
        namespace_upload.update_column(:store, FileUploader::Store::REMOTE)
        attachment_upload.update_column(:store, FileUploader::Store::REMOTE)
        favicon_upload.update_column(:store, FileUploader::Store::REMOTE)
      end

      it 'schedules jobs for uploads stored remotely and synced locally' do
        expect(subject).to receive(:schedule_job).with('avatar', avatar_upload.id)
        expect(subject).to receive(:schedule_job).with('personal_file', personal_snippet_upload.id)
        expect(subject).to receive(:schedule_job).with('file', issuable_upload.id)
        expect(subject).to receive(:schedule_job).with('namespace_file', namespace_upload.id)
        expect(subject).to receive(:schedule_job).with('attachment', attachment_upload.id)
        expect(subject).to receive(:schedule_job).with('favicon', favicon_upload.id)

        subject.perform
      end

      it 'schedules workers for uploads stored remotely and synced locally' do
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('avatar', avatar_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('personal_file', personal_snippet_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('file', issuable_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('namespace_file', namespace_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('attachment', attachment_upload.id)
        expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('favicon', favicon_upload.id)

        subject.perform
      end
    end
  end

  context 'with job artifacts' do
    let(:job_artifact_local) { create(:ci_job_artifact) }
    let(:job_artifact_remote) { create(:ci_job_artifact, :remote_store) }

    before do
      stub_artifacts_object_storage

      create(:geo_job_artifact_registry, artifact_id: job_artifact_local.id)
      create(:geo_job_artifact_registry, artifact_id: job_artifact_remote.id)
    end

    it 'schedules job for artifact stored remotely and synced locally' do
      expect(subject).to receive(:schedule_job).with('job_artifact', job_artifact_remote.id)
      expect(subject).not_to receive(:schedule_job).with(anything, job_artifact_local.id)

      subject.perform
    end

    it 'schedules worker for artifact stored remotely and synced locally' do
      expect(Geo::FileRegistryRemovalWorker).to receive(:perform_async).with('job_artifact', job_artifact_remote.id)
      expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async).with(anything, job_artifact_local.id)

      subject.perform
    end
  end

  context 'backoff time' do
    let(:cache_key) { "#{described_class.name.underscore}:skip" }

    before do
      stub_uploads_object_storage(AvatarUploader)

      allow(Rails.cache).to receive(:read).and_call_original
      allow(Rails.cache).to receive(:write).and_call_original
    end

    it 'sets the back off time when there are no pending items' do
      expect(Rails.cache).to receive(:write).with(cache_key, true, expires_in: 300.seconds).once

      subject.perform
    end

    it 'does not perform Geo::FileRegistryRemovalWorker when the backoff time is set' do
      create(:geo_file_registry, :avatar)

      expect(Rails.cache).to receive(:read).with(cache_key).and_return(true)

      expect(Geo::FileRegistryRemovalWorker).not_to receive(:perform_async)

      subject.perform
    end
  end
end
