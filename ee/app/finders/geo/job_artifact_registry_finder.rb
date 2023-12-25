# frozen_string_literal: true

module Geo
  class JobArtifactRegistryFinder < FileRegistryFinder
    # Counts all existing registries independent
    # of any change on filters / selective sync
    def count_registry
      Geo::JobArtifactRegistry.count
    end

    def count_syncable
      syncable.count
    end

    def count_synced
      registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.synced).count
    end

    def count_failed
      registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.failed).count
    end

    def count_synced_missing_on_primary
      registries_for_job_artifacts.merge(Geo::JobArtifactRegistry.synced.missing_on_primary).count
    end

    def syncable
      return job_artifacts.not_expired if selective_sync?
      return Ci::JobArtifact.not_expired.with_files_stored_locally if local_storage_only?

      Ci::JobArtifact.not_expired
    end

    # Find limited amount of non replicated job artifacts.
    #
    # You can pass a list with `except_artifact_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_artifact_ids ids that will be ignored from the query
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_artifact_ids: [])
      job_artifacts
        .not_expired
        .missing_job_artifact_registry
        .id_not_in(except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_artifact_ids: [])
      all_job_artifacts
        .inner_join_job_artifact_registry
        .with_files_stored_remotely
        .id_not_in(except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_artifact_ids: [])
      Geo::JobArtifactRegistry
        .failed
        .retry_due
        .artifact_id_not_in(except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_artifact_ids: [])
      Geo::JobArtifactRegistry
        .synced
        .missing_on_primary
        .retry_due
        .artifact_id_not_in(except_artifact_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def job_artifacts
      local_storage_only? ? all_job_artifacts.with_files_stored_locally : all_job_artifacts
    end

    def all_job_artifacts
      current_node.job_artifacts
    end

    def registries_for_job_artifacts
      job_artifacts
        .inner_join_job_artifact_registry
        .not_expired
    end
  end
end
