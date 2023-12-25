# frozen_string_literal: true

module Geo
  module Fdw
    class Upload < ::Geo::BaseFdw
      include Gitlab::SQL::Pattern
      include ObjectStorable

      STORE_COLUMN = :store

      self.primary_key = :id
      self.table_name = Gitlab::Geo::Fdw.foreign_table_name('uploads')

      has_one :registry, class_name: 'Geo::FileRegistry', foreign_key: :file_id

      class << self
        def for_model(model)
          inner_join_file_registry
            .where(model_id: model.id, model_type: model.class.name)
            .merge(Geo::FileRegistry.uploads)
        end

        def inner_join_file_registry
          joins(:registry)
        end

        def missing_file_registry
          left_outer_join_file_registry
            .where(file_registry_table[:id].eq(nil))
        end

        # Searches for a list of uploads based on the query given in `query`.
        #
        # On PostgreSQL this method uses "ILIKE" to perform a case-insensitive
        # search.
        #
        # query - The search query as a String.
        def search(query)
          fuzzy_search(query, [:path])
        end

        private

        def file_registry_table
          Geo::FileRegistry.arel_table
        end

        def left_outer_join_file_registry
          join_statement =
            arel_table
              .join(file_registry_table, Arel::Nodes::OuterJoin)
              .on(arel_table[:id].eq(file_registry_table[:file_id]).and(file_registry_table[:file_type].in(Gitlab::Geo::Replication::USER_UPLOADS_OBJECT_TYPES)))

          joins(join_statement.join_sources)
        end
      end
    end
  end
end
