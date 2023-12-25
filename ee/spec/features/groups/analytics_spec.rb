require 'spec_helper'

describe 'Groups > Contribution Analytics', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:empty_project) { create(:project, namespace: group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'visit Contribution Analytics page for group' do
    it 'displays Contribution Analytics' do
      visit group_path(group)

      find('a', text: 'Contribution Analytics').click

      expect(page).to have_content "Contribution analytics for issues, merge requests and push"
    end
  end
end
