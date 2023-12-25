# frozen_string_literal: true

module Epics
  class CreateService < Epics::BaseService
    def execute
      @epic = group.epics.new(whitelisted_epic_params)
      @epic.move_to_start if @epic.parent

      create(@epic)
    end

    private

    def before_create(epic)
      # current_user (defined in BaseService) is not available within run_after_commit block
      user = current_user
      epic.run_after_commit do
        NewEpicWorker.perform_async(epic.id, user.id)
      end
    end

    def whitelisted_epic_params
      params.slice(:title, :description, :start_date, :end_date, :milestone, :label_ids, :parent_id)
    end
  end
end
