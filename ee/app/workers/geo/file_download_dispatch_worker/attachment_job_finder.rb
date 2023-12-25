# frozen_string_literal: true

module Geo
  class FileDownloadDispatchWorker
    class AttachmentJobFinder < JobFinder
      EXCEPT_RESOURCE_IDS_KEY = :except_file_ids

      def registry_finder
        @registry_finder ||= Geo::AttachmentRegistryFinder.new(current_node_id: Gitlab::Geo.current_node.id)
      end

      private

      # Why do we need a different `file_type` for each Uploader? Why not just use 'upload'?
      # rubocop: disable CodeReuse/ActiveRecord
      def convert_resource_relation_to_job_args(relation)
        relation.pluck(:id, :uploader)
                .map { |id, uploader| [uploader.sub(/Uploader\z/, '').underscore, id] }
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # rubocop: disable CodeReuse/ActiveRecord
      def convert_registry_relation_to_job_args(relation)
        relation.pluck(:file_type, :file_id)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
