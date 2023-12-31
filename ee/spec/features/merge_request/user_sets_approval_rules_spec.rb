# frozen_string_literal: true

require 'spec_helper'

describe 'Merge request > User sets approval rules', :js do
  include ProjectForksHelper

  include_context 'project with approval rules'

  def page_rule_names
    page.all('.js-approval-rules table .js-name')
  end

  context "with project approval rules" do
    context "from a fork" do
      let(:forked_project) { fork_project(project, nil, repository: true) }

      before do
        forked_project.add_maintainer(author)
        allow(forked_project).to receive(:multiple_approval_rules_available?).and_return(false)

        sign_in(author)
        visit project_new_merge_request_path(forked_project, merge_request: { target_branch: 'master', target_project_id: project.id, source_branch: 'feature' })
        wait_for_requests
      end

      it "shows approval rules from target project" do
        names = page_rule_names
        regular_rules.each_with_index do |rule, idx|
          expect(names[idx]).to have_text(rule.name)
        end
      end
    end

    context "with a private group rule" do
      let!(:private_group) { create(:group, :private) }
      let!(:private_rule) { create(:approval_project_rule, project: project, groups: [private_group], name: 'Private Rule') }
      let!(:rules) { regular_rules + [private_rule] }

      before do
        private_group.add_developer(approver)

        sign_in(author)
        visit project_new_merge_request_path(project, merge_request: { target_branch: 'master', source_branch: 'feature' })
        wait_for_requests
      end

      it "shows approval rules" do
        names = page_rule_names
        rules.each.with_index do |rule, idx|
          expect(names[idx]).to have_text(rule.name)
        end
      end

      it "persists hidden groups that author has no access to when creating MR" do
        click_on("Submit merge request")
        wait_for_requests

        click_on("View eligible approvers")
        wait_for_requests

        tr = page.find(:css, 'tr', text: private_rule.name)
        td = tr.find(:css, '.js-approvers')

        # The approver granted by the private group is not visible
        expect(td).to have_text('None')
      end
    end
  end
end
