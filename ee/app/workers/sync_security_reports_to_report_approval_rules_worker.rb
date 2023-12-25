# frozen_string_literal: true

# Worker for syncing report_type approval_rules approvals_required
#
class SyncSecurityReportsToReportApprovalRulesWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(pipeline_id)
    pipeline = Ci::Pipeline.find_by_id(pipeline_id)
    return unless pipeline

    ::Security::SyncReportsToApprovalRulesService.new(pipeline).execute
  end
end
