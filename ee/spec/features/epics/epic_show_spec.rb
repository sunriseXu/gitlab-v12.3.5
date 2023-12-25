# frozen_string_literal: true

require 'spec_helper'

describe 'Epic show', :js do
  let(:user) { create(:user, name: 'Rick Sanchez', username: 'rick.sanchez') }
  let(:group) { create(:group, :public) }
  let(:label) { create(:group_label, group: group, title: 'bug') }
  let(:note_text) { 'Contemnit enim disserendi elegantiam.' }
  let(:epic_title) { 'Sample epic' }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    Nos commodius agimus.
    Ex rebus enim timiditas, non ex vocabulis nascitur.
    Ita prorsus, inquam; Duo Reges: constructio interrete.
    MARKDOWN
  end

  let(:epic) { create(:epic, group: group, title: epic_title, description: markdown, author: user) }
  let!(:child_epic_a) { create(:epic, group: group, title: 'Child epic A', description: markdown, parent: epic, start_date: 50.days.ago, end_date: 10.days.ago) }
  let!(:child_epic_b) { create(:epic, group: group, title: 'Child epic B', description: markdown, parent: epic, start_date: 100.days.ago, end_date: 20.days.ago) }

  before do
    group.add_developer(user)
    stub_licensed_features(epics: true)
    sign_in(user)

    visit group_epic_path(group, epic)
  end

  describe 'Epic metadata' do
    it 'shows epic status, date and author in header' do
      page.within('.epic-page-container .detail-page-header-body') do
        expect(find('.issuable-status-box > span')).to have_content('Open')
        expect(find('.issuable-meta')).to have_content('Opened just now by')
        expect(find('.issuable-meta .js-user-avatar-link-username')).to have_content('Rick Sanchez')
      end
    end

    it 'shows epic title and description' do
      page.within('.epic-page-container .detail-page-description') do
        expect(find('.title-container .title')).to have_content(epic_title)
        expect(find('.description .md')).to have_content(markdown.squish)
      end
    end

    it 'shows epic tabs' do
      page.within('.js-epic-tabs-container') do
        expect(find('.epic-tabs #tree-tab')).to have_content('Epics and Issues')
        expect(find('.epic-tabs #roadmap-tab')).to have_content('Roadmap')
      end
    end

    it 'shows epic thread filter dropdown' do
      page.within('.js-noteable-awards') do
        expect(find('.js-discussion-filter-container #discussion-filter-dropdown')).to have_content('Show all activity')
      end
    end
  end

  describe 'Epics and Issues tab' do
    it 'shows Related items tree with child epics' do
      page.within('.js-epic-tabs-content #tree') do
        expect(page).to have_selector('.related-items-tree-container')

        page.within('.related-items-tree-container') do
          expect(page.find('.issue-count-badge')).to have_content('2')
          expect(find('.tree-item:nth-child(1) .sortable-link')).to have_content('Child epic B')
          expect(find('.tree-item:nth-child(2) .sortable-link')).to have_content('Child epic A')
        end
      end
    end
  end

  describe 'Roadmap tab' do
    before do
      find('.js-epic-tabs-container #roadmap-tab').click
      wait_for_requests
    end

    it 'shows Roadmap timeline with child epics' do
      page.within('.js-epic-tabs-content #roadmap') do
        expect(page).to have_selector('.roadmap-container .roadmap-shell')

        page.within('.roadmap-shell .epics-list-section') do
          expect(find('.epics-list-item:nth-child(1) .epic-title a')).to have_content('Child epic B')
          expect(find('.epics-list-item:nth-child(2) .epic-title a')).to have_content('Child epic A')
        end
      end
    end

    it 'does not show thread filter dropdown' do
      expect(find('.js-noteable-awards')).to have_selector('.js-discussion-filter-container', visible: false)
    end

    it 'has no limit on container width' do
      expect(find('.content-wrapper .container-fluid:not(.breadcrumbs)')[:class]).not_to include('container-limited')
    end
  end
end
