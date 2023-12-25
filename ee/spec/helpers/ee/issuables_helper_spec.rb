# frozen_string_literal: true

require 'spec_helper'

describe IssuablesHelper do
  describe '#issuable_initial_data' do
    before do
      stub_commonmark_sourcepos_disabled
    end

    it 'returns the correct data for an epic' do
      user = create(:user)
      epic = create(:epic, author: user, description: 'epic text')
      @group = epic.group

      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(true)

      expected_data = {
        endpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}",
        epicLinksEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}/links",
        updateEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}.json",
        issueLinksEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}/issues",
        canUpdate: true,
        canDestroy: true,
        canAdmin: true,
        issuableRef: "&#{epic.iid}",
        markdownPreviewPath: "/groups/#{@group.full_path}/preview_markdown",
        markdownDocsPath: '/help/user/markdown',
        issuableTemplates: nil,
        lockVersion: epic.lock_version,
        fullPath: @group.full_path,
        groupPath: @group.path,
        initialTitleHtml: epic.title,
        initialTitleText: epic.title,
        initialDescriptionHtml: '<p dir="auto">epic text</p>',
        initialDescriptionText: 'epic text',
        initialTaskStatus: '0 of 0 tasks completed'
      }
      expect(helper.issuable_initial_data(epic)).to eq(expected_data)
    end
  end
end
