# frozen_string_literal: true

class ProjectUpdateRepositoryStorageWorker
  include ApplicationWorker

  def perform(project_id, new_repository_storage_key)
    project = Project.find(project_id)

    ::Projects::UpdateRepositoryStorageService.new(project).execute(new_repository_storage_key)
  rescue ::Projects::UpdateRepositoryStorageService::RepositoryAlreadyMoved
    Rails.logger.info "#{self.class}: repository already moved: #{project}" # rubocop:disable Gitlab/RailsLogger
  end
end
