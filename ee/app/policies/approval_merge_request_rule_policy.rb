# frozen_string_literal: true

class ApprovalMergeRequestRulePolicy < BasePolicy
  delegate { @subject.merge_request }

  condition(:editable) do
    can?(:update_merge_request, @subject.merge_request) && @subject.regular?
  end

  rule { editable }.enable :edit_approval_rule
end
