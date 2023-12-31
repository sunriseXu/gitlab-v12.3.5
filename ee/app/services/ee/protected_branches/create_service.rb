# frozen_string_literal: true

module EE
  module ProtectedBranches
    module CreateService
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize
      include Loggable

      override :execute
      def execute(skip_authorization: false)
        super(skip_authorization: skip_authorization).tap do |protected_branch_service|
          log_audit_event(protected_branch_service, :add)
        end
      end

      private

      override :save_protected_branch
      def save_protected_branch
        super

        sync_code_owner_approval_rules if project.feature_available?(:code_owners)

        protected_branch
      end

      def sync_code_owner_approval_rules
        merge_requests_for_protected_branch.each do |merge_request|
          ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute
        end
      end

      def merge_requests_for_protected_branch
        strong_memoize(:protected_branch_merge_requests) do
          if protected_branch.wildcard?
            merge_requests_for_wildcard_branch
          else
            merge_requests_for_branch
          end
        end
      end

      def merge_requests_for_wildcard_branch
        project.merge_requests
          .open_and_closed
          .by_target_branch_wildcard(protected_branch.name)
          .preload_source_project
          .select(&:source_project)
      end

      def merge_requests_for_branch
        project.merge_requests
          .open_and_closed
          .by_target_branch(protected_branch.name)
          .preload_source_project
          .select(&:source_project)
      end
    end
  end
end
