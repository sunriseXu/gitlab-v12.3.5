# frozen_string_literal: true

# Agnostic proxy to decide which version of elastic_target to use based on method being reads or writes
module Elastic
  class MultiVersionClassProxy
    include MultiVersionUtil

    def initialize(data_target)
      @data_target = data_target
      @data_class = get_data_class(data_target)

      generate_forwarding
    end

    def version(version)
      super.tap do |elastic_target|
        elastic_target.extend Elasticsearch::Model::Importing::ClassMethods
        elastic_target.extend Elasticsearch::Model::Adapter.from_class(@data_class).importing_mixin
      end
    end

    def proxy_class_name
      "#{@data_class.name}ClassProxy"
    end
  end
end
