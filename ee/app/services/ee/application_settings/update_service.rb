# frozen_string_literal: true

module EE
  module ApplicationSettings
    module UpdateService
      extend ::Gitlab::Utils::Override
      extend ActiveSupport::Concern

      override :execute
      def execute
        # Repository size limit comes as MB from the view
        limit = params.delete(:repository_size_limit)
        application_setting.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

        elasticsearch_namespace_ids = params.delete(:elasticsearch_namespace_ids)
        elasticsearch_project_ids = params.delete(:elasticsearch_project_ids)

        if result = super
          update_elasticsearch_containers(ElasticsearchIndexedNamespace, elasticsearch_namespace_ids)
          update_elasticsearch_containers(ElasticsearchIndexedProject, elasticsearch_project_ids)
        end

        result
      end

      def update_elasticsearch_containers(klass, new_container_ids)
        return unless application_setting.elasticsearch_limit_indexing?

        new_container_ids = new_container_ids&.split(",") unless new_container_ids.is_a?(Array)
        return if new_container_ids.nil?

        # Destroy any containers that have been removed. This runs callbacks, etc
        klass.remove_all(except: new_container_ids)

        # Disregard any duplicates that are already present
        new_container_ids -= klass.target_ids

        # Add new containers
        new_container_ids.each { |id| klass.create(klass.target_attr_name => id) }
      end
    end
  end
end
