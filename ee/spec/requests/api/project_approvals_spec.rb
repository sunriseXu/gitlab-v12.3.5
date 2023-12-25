require 'spec_helper'

describe API::ProjectApprovals do
  set(:group)    { create(:group_with_members) }
  set(:user)     { create(:user) }
  set(:user2)    { create(:user) }
  set(:admin)    { create(:user, :admin) }
  set(:project)  { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  set(:approver) { create(:user) }

  let(:url) { "/projects/#{project.id}/approvals" }

  describe 'GET /projects/:id/approvals' do
    context 'when the request is correct' do
      before do
        create(:approval_project_rule, project: project, users: [approver], groups: [group])

        get api(url, user)
      end

      it 'returns 200 status' do
        expect(response).to have_gitlab_http_status(200)
      end

      it 'matches the response schema' do
        expect(response).to match_response_schema('public_api/v4/project_approvers', dir: 'ee')
      end
    end

    it 'only shows approver groups that are visible to the user' do
      private_group = create(:group, :private)
      create(:approval_project_rule, project: project, users: [approver], groups: [private_group])

      get api(url, user)

      expect(response).to match_response_schema('public_api/v4/project_approvers', dir: 'ee')
      expect(json_response["approver_groups"]).to be_empty
    end
  end

  describe 'POST /projects/:id/approvals' do
    shared_examples_for 'a user with access' do
      context 'when missing parameters' do
        it 'returns 400 status' do
          post api(url, current_user)

          expect(response).to have_gitlab_http_status(400)
        end
      end

      context 'when the request is correct' do
        it 'returns 201 status' do
          post api(url, current_user), params: { approvals_before_merge: 3 }

          expect(response).to have_gitlab_http_status(201)
        end

        it 'matches the response schema' do
          post api(url, current_user), params: { approvals_before_merge: 3 }

          expect(response).to match_response_schema('public_api/v4/project_approvers', dir: 'ee')
        end

        it 'changes settings properly' do
          project.approvals_before_merge = 2
          project.reset_approvals_on_push = false
          project.disable_overriding_approvers_per_merge_request = true
          project.merge_requests_author_approval = false
          project.merge_requests_disable_committers_approval = true
          project.save

          settings = {
            approvals_before_merge: 4,
            reset_approvals_on_push: true,
            disable_overriding_approvers_per_merge_request: false,
            merge_requests_author_approval: true,
            merge_requests_disable_committers_approval: false
          }

          post api(url, current_user), params: settings

          expect(json_response.symbolize_keys).to include(settings)
        end

        it 'only shows approver groups that are visible to the current user' do
          private_group = create(:group, :private)
          project.approver_groups.create(group: private_group)

          post api(url, current_user), params: { approvals_before_merge: 3 }

          expect(response).to match_response_schema('public_api/v4/project_approvers', dir: 'ee')
          expect(json_response["approver_groups"].size).to eq(visible_approver_groups_count)
        end
      end
    end

    context 'as a project admin' do
      it_behaves_like 'a user with access' do
        let(:current_user) { user }
        let(:visible_approver_groups_count) { 0 }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'a user with access' do
        let(:current_user) { admin }
        let(:visible_approver_groups_count) { 1 }
      end
    end

    context 'as a user without access' do
      it 'returns 403' do
        post api(url, user2), params: { approvals_before_merge: 4 }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'PUT /projects/:id/approvers' do
    let(:url) { "/projects/#{project.id}/approvers" }

    shared_examples_for 'a user with access' do
      it 'removes all approvers if no params are given' do
        project.approvers.create(user: approver)

        expect do
          put api(url, current_user), params: { approver_ids: [], approver_group_ids: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
        end.to change { project.approvers.count }.from(1).to(0)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approvers']).to be_empty
        expect(json_response['approver_groups']).to be_empty
      end

      context 'when sending form-encoded data' do
        it 'removes all approvers if no params are given' do
          project.approvers.create(user: approver)

          expect do
            put api(url, current_user), params: { approver_ids: '', approver_group_ids: '' }
          end.to change { project.approvers.count }.from(1).to(0)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['approvers']).to be_empty
          expect(json_response['approver_groups']).to be_empty
        end
      end

      it 'sets approvers and approver groups' do
        project.approvers.create(user: approver)

        expect do
          put api(url, current_user), params: { approver_ids: [approver.id], approver_group_ids: [group.id] }
        end.to change { project.approvers.count }.by(0).and change { project.approver_groups.count }.from(0).to(1)

        expect(project.approvers.count).to eq(1)
        expect(project.approvers.first.user_id).to eq(approver.id)
        expect(project.approver_groups.first.group_id).to eq(group.id)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['approvers'][0]['user']['username']).to eq(approver.username)
        expect(json_response['approver_groups'][0]['group']['name']).to eq(group.name)
      end

      it 'only shows approver groups that are visible to the current user' do
        private_group = create(:group, :private)
        project.approvers.create(user: approver)

        expect do
          put api(url, current_user), params: { approver_ids: [approver.id], approver_group_ids: [private_group.id] }
        end.to change { project.approver_groups.count }.from(0).to(1)

        expect(response).to match_response_schema('public_api/v4/project_approvers', dir: 'ee')
        expect(json_response["approver_groups"].size).to eq(visible_approver_groups_count)
      end
    end

    context 'as a project admin' do
      it_behaves_like 'a user with access' do
        let(:current_user) { user }
        let(:visible_approver_groups_count) { 0 }
      end
    end

    context 'as a global admin' do
      it_behaves_like 'a user with access' do
        let(:current_user) { admin }
        let(:visible_approver_groups_count) { 1 }
      end
    end

    context 'as a random user' do
      it 'returns 403' do
        project.approvers.create(user: approver)

        expect do
          put api(url, user2), params: { approver_ids: [], approver_group_ids: [] }.to_json, headers: { CONTENT_TYPE: 'application/json' }
        end.not_to change { project.approvers.count }

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end
end
