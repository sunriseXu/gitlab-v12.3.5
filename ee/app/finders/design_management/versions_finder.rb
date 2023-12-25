# frozen_string_literal: true

module DesignManagement
  class VersionsFinder
    attr_reader :design_or_collection, :current_user, :params

    # The `design_or_collection` argument should be either a:
    #
    # - DesignManagement::Design, or
    # - DesignManagement::DesignCollection
    #
    # The object will have `#versions` called on it to set up the
    # initial scope of the versions.
    def initialize(design_or_collection, current_user, params = {})
      @design_or_collection = design_or_collection
      @current_user = current_user
      @params = params
    end

    def execute
      unless Ability.allowed?(current_user, :read_design, design_or_collection)
        return ::DesignManagement::Version.none
      end

      items = design_or_collection.versions
      items = by_earlier_or_equal_to(items)
      items.ordered
    end

    private

    def by_earlier_or_equal_to(items)
      return items unless params[:earlier_or_equal_to]

      items.earlier_or_equal_to(params[:earlier_or_equal_to])
    end
  end
end
