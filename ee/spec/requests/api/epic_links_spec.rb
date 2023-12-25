# frozen_string_literal: true

require 'spec_helper'

describe API::EpicLinks do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:epic) { create(:epic, group: group) }

  shared_examples 'user does not have access' do
    it 'returns 403 when epics feature is disabled' do
      group.add_developer(user)

      subject

      expect(response).to have_gitlab_http_status(403)
    end

    context 'unauthenticated user' do
      let(:user) { nil }

      it 'returns 401 unauthorized error' do
        subject

        expect(response).to have_gitlab_http_status(401)
      end
    end

    it 'returns 404 not found error for a user without permissions to see the group' do
      group.update(visibility_level: Gitlab::VisibilityLevel::PRIVATE)

      subject

      expect(response).to have_gitlab_http_status(404)
    end
  end

  describe 'GET /groups/:id/epics/:epic_iid/epics' do
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/epics" }

    subject { get api(url, user) }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      let!(:child_epic1) { create(:epic, group: group, parent: epic, relative_position: 200) }
      let!(:child_epic2) { create(:epic, group: group, parent: epic, relative_position: 100) }

      it 'returns 200 status' do
        subject

        epics = json_response

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
        expect(epics.map { |epic| epic["id"] }).to eq([child_epic2.id, child_epic1.id])
      end
    end
  end

  describe 'POST /groups/:id/epics/:epic_iid/epics/child_epic_id' do
    let(:child_epic) { create(:epic, group: group) }
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/epics/#{child_epic.id}" }

    subject { post api(url, user) }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user is guest' do
        it 'returns 403' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user is developer' do
        it 'returns 201 status' do
          group.add_developer(user)

          subject

          expect(response).to have_gitlab_http_status(201)
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
          expect(epic.reload.children).to include(child_epic)
        end
      end

      context 'when target epic cannot be read' do
        let(:other_group) { create(:group, :private) }
        let(:child_epic) { create(:epic, group: other_group) }

        it 'returns 404 status' do
          group.add_developer(user)

          subject

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'POST /groups/:id/epics/:epic_iid/epics' do
    let(:url) { "/groups/#{group.path}/-/epics/#{epic.iid}/epics" }

    subject { post api(url, user), params: { title: 'child epic' } }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user is guest' do
        it 'returns 403' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user is developer' do
        it 'returns 201 status' do
          group.add_developer(user)

          subject

          expect(response).to have_gitlab_http_status(201)
          expect(response).to match_response_schema('public_api/v4/linked_epic', dir: 'ee')
          expect(epic.reload.children).to include(Epic.last)
        end
      end
    end
  end

  describe 'PUT /groups/:id/epics/:epic_iid/epics/:child_epic_id' do
    let!(:child_epic) { create(:epic, group: group, parent: epic, relative_position: 100) }
    let!(:sibling_1) { create(:epic, group: group, parent: epic, relative_position: 200) }
    let!(:sibling_2) { create(:epic, group: group, parent: epic, relative_position: 300) }

    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/epics/#{child_epic.id}" }

    subject { put api(url, user), params: { move_before_id: sibling_1.id, move_after_id: sibling_2.id } }

    it_behaves_like 'user does not have access'

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to reorder epics' do
        before do
          group.add_developer(user)
        end

        it 'returns status 200' do
          subject

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/epics', dir: 'ee')
          expect(json_response.map { |epic| epic['id'] }).to eq([sibling_1.id, child_epic.id, sibling_2.id])
        end
      end

      context 'when user does not have permissions to reorder epics' do
        it 'returns status 403' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end
  end

  describe 'DELETE /groups/:id/epics/:epic_iid/epics' do
    let!(:child_epic) { create(:epic, group: group, parent: epic)}
    let(:url) { "/groups/#{group.path}/epics/#{epic.iid}/epics/#{child_epic.id}" }

    subject { delete api(url, user) }

    it_behaves_like 'user does not have access'

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user is guest' do
        it 'returns 403' do
          group.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when user is developer' do
        it 'returns 200 status' do
          group.add_developer(user)

          subject

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('public_api/v4/epic', dir: 'ee')
          expect(epic.reload.children).not_to include(child_epic)
        end
      end
    end
  end
end
