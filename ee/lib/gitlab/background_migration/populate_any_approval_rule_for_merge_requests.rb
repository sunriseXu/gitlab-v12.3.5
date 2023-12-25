# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This background migration creates any approver rule records according
    # to the given merge request IDs range. A _single_ INSERT is issued for the given range.
    class PopulateAnyApprovalRuleForMergeRequests
      def perform(from_id, to_id)
        select_sql =
          MergeRequest
            .where(merge_request_approval_rules_not_exists_clause)
            .where(id: from_id..to_id)
            .where('approvals_before_merge <> 0')
            .select("id, approvals_before_merge, created_at, updated_at, 4, '#{ApprovalRuleLike::ALL_MEMBERS}'")
            .to_sql

        execute("INSERT INTO approval_merge_request_rules (merge_request_id, approvals_required, created_at, updated_at, rule_type, name) #{select_sql}")
      end

      private

      def merge_request_approval_rules_not_exists_clause
        <<~SQL
            NOT EXISTS (SELECT 1 FROM approval_merge_request_rules
                        WHERE approval_merge_request_rules.merge_request_id = merge_requests.id)
        SQL
      end

      def execute(sql)
        @connection ||= ActiveRecord::Base.connection
        @connection.execute(sql)
      end
    end
  end
end
