# frozen_string_literal: true

module Elastic
  class IndexRecordService
    include Elasticsearch::Model::Client::ClassMethods

    ImportError = Class.new(StandardError)

    ISSUE_TRACKED_FIELDS = %w(assignee_ids author_id confidential).freeze
    IMPORT_RETRY_COUNT = 3

    # @param indexing [Boolean] determines whether operation is "indexing" or "updating"
    def execute(record, indexing, options = {})
      return true unless record.use_elasticsearch?

      record.__elasticsearch__.client = client

      import(record, record.class.nested?, indexing)

      initial_index_project(record) if record.class == Project && indexing

      update_issue_notes(record, options["changed_fields"]) if record.class == Issue

      true
    rescue Elasticsearch::Transport::Transport::Errors::NotFound, ActiveRecord::RecordNotFound
      # These errors can happen in several cases, including:
      # - A record is updated, then removed before the update is handled
      # - Indexing is enabled, but not every item has been indexed yet - updating
      #   and deleting the un-indexed records will raise exception
      #
      # We can ignore these.
      true
    end

    private

    def update_issue_notes(record, changed_fields)
      if changed_fields && (changed_fields & ISSUE_TRACKED_FIELDS).any?
        import_association(Note, query: -> { where(noteable: record) })
      end
    end

    def initial_index_project(project)
      # Enqueue the repository indexing jobs immediately so they run in parallel
      # One for the project repository, one for the wiki repository
      ElasticCommitIndexerWorker.perform_async(project.id)
      ElasticCommitIndexerWorker.perform_async(project.id, nil, nil, true)

      project.each_indexed_association do |klass, association|
        import_association(association)
      end
    end

    def import_association(association, options = {})
      options[:return] = 'errors'

      errors = association.es_import(options)
      return if errors.empty?

      IMPORT_RETRY_COUNT.times do
        errors = retry_import(errors, association, options)
        return if errors.empty?
      end

      raise ImportError.new(errors.inspect)
    end

    def import(record, nested, indexing)
      operation = indexing ? 'index_document' : 'update_document'
      response = nil

      IMPORT_RETRY_COUNT.times do
        response = if nested
                     record.__elasticsearch__.__send__ operation, routing: record.es_parent # rubocop:disable GitlabSecurity/PublicSend
                   else
                     record.__elasticsearch__.__send__ operation # rubocop:disable GitlabSecurity/PublicSend
                   end

        return if response['_shards']['successful'] > 0
      end

      raise ImportError.new(response)
    end

    def retry_import(errors, association, options)
      ids = errors.map { |error| error['index']['_id'][/_(\d+)$/, 1] }
      association.id_in(ids).es_import(options)
    end
  end
end
