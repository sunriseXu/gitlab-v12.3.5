# frozen_string_literal: true

module EE
  module Git
    module BranchPushService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        enqueue_elasticsearch_indexing
        enqueue_update_external_pull_requests

        super
      end

      private

      def enqueue_elasticsearch_indexing
        return unless should_index_commits?

        project.repository.index_commits_and_blobs(from_rev: params[:oldrev], to_rev: params[:newrev])
      end

      def enqueue_update_external_pull_requests
        return unless project.mirror?
        return unless params.fetch(:create_pipelines, true)

        UpdateExternalPullRequestsWorker.perform_async(
          project.id,
          current_user.id,
          params[:ref]
        )
      end

      def should_index_commits?
        return false unless default_branch?
        return false unless project.use_elasticsearch?

        # Check that we're not already indexing this project
        ::Gitlab::Redis::SharedState.with do |redis|
          !redis.sismember(:elastic_projects_indexing, project.id)
        end
      end
    end
  end
end
