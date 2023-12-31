# frozen_string_literal: true

require 'spec_helper'

describe RefreshLicenseComplianceChecksWorker do
  subject { described_class.new }

  describe '#perform' do
    let(:project) { create(:project) }

    before do
      stub_licensed_features(license_management: true)
    end

    context "when there are merge requests associated with the project" do
      let!(:open_merge_request) { create(:merge_request, :opened, target_project: project, source_project: project) }
      let!(:closed_merge_request) { create(:merge_request, :closed, target_project: project, source_project: project) }

      context "when the `#{ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT}` approval rule is enabled" do
        let!(:open_merge_request_approval_rule) { create(:report_approver_rule, :requires_approval, :license_management, merge_request: open_merge_request) }
        let!(:closed_merge_request_approval_rule) { create(:report_approver_rule, :license_management, merge_request: closed_merge_request, approvals_required: 0) }
        let!(:project_approval_rule) { create(:approval_project_rule, :requires_approval, :license_management, project: project) }

        context "when a license is blacklisted, that appears in some of the license management reports" do
          let!(:open_pipeline) { create(:ee_ci_pipeline, :success, :with_license_management_report, project: project, merge_requests_as_head_pipeline: [open_merge_request]) }
          let!(:closed_pipeline) { create(:ee_ci_pipeline, :success, :with_license_management_report, project: project, merge_requests_as_head_pipeline: [closed_merge_request]) }
          let!(:blacklist_policy) { create(:software_license_policy, project: project, software_license: license, approval_status: :blacklisted) }
          let(:license) { create(:software_license, name: license_report.license_names[0]) }
          let(:license_report) { open_pipeline.license_management_report }

          before do
            subject.perform(project.id)
          end

          specify { expect(open_merge_request_approval_rule.reload.approvals_required).to eql(project_approval_rule.approvals_required) }
          specify { expect(closed_merge_request_approval_rule.reload.approvals_required).to be_zero }
        end

        context "when none of the blacklisted licenses appear in the most recent license management reports" do
          let!(:open_pipeline) { create(:ee_ci_pipeline, :success, :with_license_management_report, project: project, merge_requests_as_head_pipeline: [open_merge_request]) }
          let!(:closed_pipeline) { create(:ee_ci_pipeline, :success, :with_license_management_report, project: project, merge_requests_as_head_pipeline: [closed_merge_request]) }
          let!(:blacklist_policy) { create(:software_license_policy, project: project, software_license: license, approval_status: :blacklisted) }
          let(:license) { create(:software_license, name: SecureRandom.uuid) }

          before do
            subject.perform(project.id)
          end

          specify { expect(open_merge_request_approval_rule.reload.approvals_required).to be_zero }
          specify { expect(closed_merge_request_approval_rule.reload.approvals_required).to be_zero }
        end
      end
    end

    context "when the project does not exist" do
      specify do
        expect { subject.perform(SecureRandom.uuid) }.not_to raise_error
      end
    end

    context "when the project does not have a license check rule" do
      specify do
        expect { subject.perform(project.id) }.not_to raise_error
      end
    end
  end
end
