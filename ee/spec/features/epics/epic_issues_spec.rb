require 'spec_helper'

describe 'Epic Issues', :js do
  include DragTo

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:public_project) { create(:project, :public, group: group) }
  let(:private_project) { create(:project, :private, group: group) }
  let(:public_issue) { create(:issue, project: public_project) }
  let(:private_issue) { create(:issue, project: private_project) }

  let!(:epic_issues) do
    [
      create(:epic_issue, epic: epic, issue: public_issue, relative_position: 1),
      create(:epic_issue, epic: epic, issue: private_issue, relative_position: 2)
    ]
  end

  let!(:nested_epics) do
    [
      create(:epic, group: group, parent_id: epic.id, relative_position: 1),
      create(:epic, group: group, parent_id: epic.id, relative_position: 2)
    ]
  end

  def visit_epic
    stub_licensed_features(epics: true)

    sign_in(user)
    visit group_epic_path(group, epic)

    wait_for_requests

    find('.js-epic-tabs-container #tree-tab').click

    wait_for_requests
  end

  context 'when user is not a group member of a public group' do
    before do
      visit_epic
    end

    it 'user can see issues from public project but cannot delete the associations' do
      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li', count: 3)
        expect(page).to have_content(public_issue.title)
        expect(page).not_to have_selector('button.js-issue-item-remove-button')
      end
    end

    it 'user cannot add new issues to the epic' do
      expect(page).not_to have_selector('.related-items-tree-container .js-add-issues-button')
    end

    it 'user cannot add new epics to the epic' do
      expect(page).not_to have_selector('.related-items-tree-container .js-add-epics-button')
    end
  end

  context 'when user is a group member' do
    let(:issue_to_add) { create(:issue, project: private_project) }
    let(:issue_invalid) { create(:issue) }
    let(:epic_to_add) { create(:epic, group: group) }

    def add_issues(references)
      find('.related-items-tree-container .js-add-issues-button').click
      find('.related-items-tree-container .js-add-issuable-form-input').set(references)
      # When adding long references, for some reason the input gets stuck
      # waiting for more text. Send a keystroke before clicking the button to
      # get out of this mode.
      find('.related-items-tree-container .js-add-issuable-form-input').send_keys(:tab)
      find('.related-items-tree-container .js-add-issuable-form-add-button').click

      wait_for_requests
    end

    def add_epics(references)
      find('.related-items-tree-container .js-add-epics-button').click
      find('.related-items-tree-container .js-add-issuable-form-input').set(references)

      find('.related-items-tree-container .js-add-issuable-form-input').send_keys(:tab)
      find('.related-items-tree-container .js-add-issuable-form-add-button').click

      wait_for_requests
    end

    before do
      group.add_developer(user)
      visit_epic
    end

    it 'user can see all issues of the group and delete the associations' do
      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li.js-item-type-issue', count: 2)
        expect(page).to have_content(public_issue.title)
        expect(page).to have_content(private_issue.title)

        first('li.js-item-type-issue button.js-issue-item-remove-button').click
      end
      first('#item-remove-confirmation .modal-footer .btn-danger').click

      wait_for_requests

      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li.js-item-type-issue', count: 1)
      end
    end

    it 'user can see all epics of the group and delete the associations' do
      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li.js-item-type-epic', count: 2)
        expect(page).to have_content(nested_epics[0].title)
        expect(page).to have_content(nested_epics[1].title)

        first('li.js-item-type-epic button.js-issue-item-remove-button').click
      end
      first('#item-remove-confirmation .modal-footer .btn-danger').click

      wait_for_requests

      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li.js-item-type-epic', count: 1)
      end
    end

    it 'user cannot add new issues to the epic from another group' do
      add_issues("#{issue_invalid.to_reference(full: true)}")

      expect(page).to have_selector('.content-wrapper .flash-text')
      expect(find('.flash-alert')).to have_text("We can't find an issue that matches what you are looking for.")
    end

    it 'user can add new issues to the epic' do
      references = "#{issue_to_add.to_reference(full: true)}"

      add_issues(references)

      expect(page).not_to have_selector('.content-wrapper .flash-text')
      expect(page).not_to have_content("We can't find an issue that matches what you are looking for.")

      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li.js-item-type-issue', count: 3)
      end
    end

    it 'user can add new epics to the epic' do
      references = "#{epic_to_add.to_reference(full: true)}"
      add_epics(references)

      expect(page).not_to have_selector('.content-wrapper .flash-text')
      expect(page).not_to have_content("We can't find an epic that matches what you are looking for.")

      within('.related-items-tree-container ul.related-items-list') do
        expect(page).to have_selector('li.js-item-type-epic', count: 3)
      end
    end
  end
end
