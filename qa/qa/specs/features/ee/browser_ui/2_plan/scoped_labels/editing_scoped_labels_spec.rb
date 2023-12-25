# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Editing scoped labels on issues' do
      let(:initial_label) { 'animal::fox' }
      let(:new_label_same_scope) { 'animal::dolphin' }
      let(:new_label_different_scope) { 'plant::orchid' }

      let(:initial_label_multi_colon) { 'group::car::ferrari' }
      let(:new_label_same_scope_multi_colon) { 'group::car::porsche' }
      let(:new_label_different_scope_multi_colon) { 'group::truck::mercedes-bens' }

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'Issue to test scoped labels'
          issue.labels = [initial_label, initial_label_multi_colon]
        end

        [
          new_label_same_scope,
          new_label_different_scope,
          new_label_same_scope_multi_colon,
          new_label_different_scope_multi_colon
        ].each do |label|
          Resource::Label.fabricate_via_api! do |l|
            l.project = issue.project
            l.title = label
          end
        end

        issue.visit!
      end

      it 'correctly applies simple and multiple colon scoped pairs labels' do
        Page::Project::Issue::Show.perform do |show|
          show.select_labels_and_refresh([
            new_label_same_scope,
            new_label_different_scope,
            new_label_same_scope_multi_colon,
            new_label_different_scope_multi_colon
          ])

          initial_labels = "#{initial_label} #{initial_label_multi_colon}"
          new_labels = "#{new_label_same_scope} #{new_label_same_scope_multi_colon} #{new_label_different_scope_multi_colon} #{new_label_different_scope}"

          expect(page).to have_content("added #{initial_labels}")
          expect(page).to have_content("added #{new_labels} scoped labels and automatically removed #{initial_labels}")
          expect(show.text_of_labels_block).to have_content(new_label_same_scope)
          expect(show.text_of_labels_block).to have_content(new_label_different_scope)
          expect(show.text_of_labels_block).not_to have_content(initial_label)
          expect(show.text_of_labels_block).to have_content(new_label_same_scope_multi_colon)
          expect(show.text_of_labels_block).to have_content(new_label_different_scope_multi_colon)
          expect(show.text_of_labels_block).not_to have_content(initial_label_multi_colon)
        end
      end
    end
  end
end
