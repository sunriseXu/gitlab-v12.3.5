# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issue board focus mode' do
      let(:project) do
        QA::Resource::Project.fabricate_via_api! do |project|
          project.name = 'sample-project-issue-board-focus-mode'
        end
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      it 'focuses on issue board' do
        project.visit!

        Page::Project::Menu.perform(&:go_to_boards)
        EE::Page::Project::Issue::Board::Show.perform do |show|
          show.click_focus_mode_button

          expect(show.focused_board).to be_visible
        end
      end
    end
  end
end
