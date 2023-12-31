# frozen_string_literal: true

module Elastic
  module Latest
    class MilestoneClassProxy < ApplicationClassProxy
      def nested?
        true
      end

      def elastic_search(query, options: {})
        options[:in] = %w(title^2 description)

        query_hash = basic_query_hash(options[:in], query)

        query_hash = project_ids_filter(query_hash, options)

        search(query_hash)
      end
    end
  end
end
