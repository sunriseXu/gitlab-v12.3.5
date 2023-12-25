# frozen_string_literal: true

module EE
  module Gitlab
    module QuickActions
      module IssueActions
        extend ActiveSupport::Concern
        include ::Gitlab::QuickActions::Dsl

        included do
          desc _('Add to epic')
          explanation _('Adds an issue to an epic.')
          execution_message _('Added an issue to an epic.')
          types Issue
          condition do
            quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          params '<&epic | group&epic | Epic URL>'
          command :epic do |epic_param|
            @updates[:epic] = extract_epic(epic_param)
          end

          desc _('Remove from epic')
          explanation _('Removes an issue from an epic.')
          execution_message _('Removed an issue from an epic.')
          types Issue
          condition do
            quick_action_target.persisted? &&
              quick_action_target.project.group&.feature_available?(:epics) &&
              current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
          end
          command :remove_epic do
            @updates[:epic] = nil
          end

          desc _('Promote issue to an epic')
          explanation _('Promote issue to an epic.')
          warning _('may expose confidential information')
          types Issue
          condition do
            quick_action_target.persisted? &&
              current_user.can?(:admin_issue, project) &&
              current_user.can?(:create_epic, project.group)
          end
          command :promote do
            Epics::IssuePromoteService.new(quick_action_target.project, current_user).execute(quick_action_target)
            @execution_message[:promote] = _('Promoted issue to an epic.')
          end

          def extract_epic(params)
            return if params.nil?

            extract_references(params, :epic).first
          end
        end
      end
    end
  end
end
