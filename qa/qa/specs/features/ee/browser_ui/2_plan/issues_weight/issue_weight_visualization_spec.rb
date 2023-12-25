# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issues weight visualization' do
      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      let(:project) do
        QA::Resource::Project.fabricate_via_api! do |project|
          project.name = 'the-lord-of-the-rings'
        end
      end

      let(:milestone) do
        QA::EE::Resource::ProjectMilestone.fabricate_via_api! do |m|
          m.project = project
          m.title = 'the-fellowship-of-the-ring'
        end
      end

      let(:weight) { 1000 }

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.milestone = milestone
          issue.project = project
          issue.title = 'keep-the-ring-safe'
          issue.weight = weight
        end
      end

      it 'shows the set weight in the issue page, in the milestone page, and in the issues list page' do
        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          expect(show.weight_label_value).to have_content(weight)

          show.click_milestone_link
        end

        Page::Project::Milestone::Index.perform do |index|
          expect(index.total_issue_weight_value).to have_content(weight)
        end

        Page::Project::Menu.perform(&:click_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index.issuable_weight).to have_content(weight)
        end
      end
    end
  end
end
