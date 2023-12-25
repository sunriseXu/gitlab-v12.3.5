# frozen_string_literal: true

class RepositoryPushAuditEventWorker
  include ApplicationWorker

  def perform(changes, project_id, user_id)
    project = Project.find(project_id)
    user = User.find(user_id)

    changes.map! do |change|
      before, after, ref = change['before'], change['after'], change['ref']

      service = EE::AuditEvents::RepositoryPushAuditEventService
        .new(user, project, ref, before, after)
        .tap { |event| event.prepare_security_event }

      # Checking if it's enabled and reusing the changes array
      # is mostly a memory optimization.
      service if service.enabled?
    end.compact!

    EE::AuditEvents::BulkInsertService.new(changes).execute
  end
end
