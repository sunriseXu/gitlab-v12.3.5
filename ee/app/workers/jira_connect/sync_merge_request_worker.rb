# frozen_string_literal: true

module JiraConnect
  class SyncMergeRequestWorker
    include ApplicationWorker

    queue_namespace :jira_connect

    def perform(merge_request_id)
      merge_request = MergeRequest.find_by_id(merge_request_id)

      return unless merge_request && merge_request.project

      JiraConnect::SyncService.new(merge_request.project).execute(merge_requests: [merge_request])
    end
  end
end
