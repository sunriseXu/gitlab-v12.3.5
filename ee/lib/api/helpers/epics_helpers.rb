# frozen_string_literal: true

module API
  module Helpers
    module EpicsHelpers
      def authorize_epics_feature!
        forbidden! unless user_group.feature_available?(:epics)
      end

      def authorize_can_read!
        authorize!(:read_epic, epic)
      end

      def authorize_can_admin!
        authorize!(:admin_epic, epic)
      end

      def authorize_can_create!
        authorize!(:admin_epic, user_group)
      end

      def authorize_can_destroy!
        authorize!(:destroy_epic, epic)
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def epic
        @epic ||= user_group.epics.find_by(iid: params[:epic_iid])
      end

      def find_epics(finder_params: {}, preload: nil)
        args = declared_params.merge(finder_params)
        args[:label_name] = args.delete(:labels)

        epics = EpicsFinder.new(current_user, args).execute.preload(preload)

        if args[:order_by] && args[:sort]
          epics.reorder(args[:order_by] => args[:sort])
        else
          epics
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
