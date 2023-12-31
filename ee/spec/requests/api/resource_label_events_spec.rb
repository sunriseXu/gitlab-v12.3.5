# frozen_string_literal: true

require 'spec_helper'

describe API::ResourceLabelEvents do
  set(:user) { create(:user) }

  before do
    parent.add_developer(user)
  end

  context 'when eventable is an Epic' do
    before do
      parent.add_owner(user)
      stub_licensed_features(epics: true)
    end

    it_behaves_like 'resource_label_events API', 'groups', 'epics', 'id' do
      let(:parent) { create(:group, :public) }
      let(:eventable) { create(:epic, group: parent, author: user) }
      let(:label) { create(:group_label, group: parent) }
    end
  end
end
