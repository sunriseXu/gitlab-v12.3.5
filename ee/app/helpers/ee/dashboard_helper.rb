# frozen_string_literal: true

module EE
  module DashboardHelper
    extend ::Gitlab::Utils::Override

    def controller_action_to_child_dashboards(controller = controller_name, action = action_name)
      case "#{controller}##{action}"
      when 'projects#index', 'root#index', 'projects#starred', 'projects#trending'
        %w(projects)
      when 'dashboard#activity'
        %w(starred_project_activity project_activity)
      when 'groups#index'
        %w(groups)
      when 'todos#index'
        %w(todos)
      when 'dashboard#issues'
        %w(issues)
      when 'dashboard#merge_requests'
        %w(merge_requests)
      else
        []
      end
    end

    def user_default_dashboard?(user)
      controller_action_to_child_dashboards.any? {|dashboard| dashboard == user.dashboard }
    end

    def has_start_trial?
      !current_license && current_user.admin?
    end

    private

    override :get_dashboard_nav_links
    def get_dashboard_nav_links
      super.tap do |links|
        links << :analytics if ::Gitlab::Analytics.any_features_enabled?
      end
    end
  end
end
