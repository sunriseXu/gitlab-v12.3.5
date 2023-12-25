# frozen_string_literal: true

module Geo
  class FileDownloadDispatchWorker
    class JobArtifactJobFinder < JobFinder
      RESOURCE_ID_KEY = :artifact_id
      EXCEPT_RESOURCE_IDS_KEY = :except_artifact_ids
      FILE_SERVICE_OBJECT_TYPE = :job_artifact

      def registry_finder
        @registry_finder ||= Geo::JobArtifactRegistryFinder.new(current_node_id: Gitlab::Geo.current_node.id)
      end
    end
  end
end
