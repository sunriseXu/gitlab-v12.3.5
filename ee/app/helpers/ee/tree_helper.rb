# frozen_string_literal: true

module EE
  module TreeHelper
    extend ::Gitlab::Utils::Override

    override :tree_content_data
    def tree_content_data(logs_path, project, path)
      super.merge({
        "path-locks-available" => project.feature_available?(:file_locks).to_s,
        "path-locks-toggle" => toggle_project_path_locks_path(project),
        "path-locks-path" => path
      })
    end
  end
end
