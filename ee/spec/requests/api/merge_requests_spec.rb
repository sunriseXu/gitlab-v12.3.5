require "spec_helper"

describe API::MergeRequests do
  include ProjectForksHelper

  let(:base_time)   { Time.now }
  let(:user)        { create(:user) }
  let(:user2)       { create(:user) }
  let!(:project)    { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  let(:milestone)   { create(:milestone, title: '1.0.0', project: project) }
  let(:milestone1) { create(:milestone, title: '0.9', project: project) }
  let!(:merge_request) { create(:merge_request, :simple, milestone: milestone1, author: user, assignees: [user, user2], source_project: project, target_project: project, title: "Test", created_at: base_time) }
  let!(:label) do
    create(:label, title: 'label', color: '#FFAABB', project: project)
  end
  let!(:label2) { create(:label, title: 'a-test', color: '#FFFFFF', project: project) }

  before do
    project.add_reporter(user)
  end

  describe 'PUT /projects/:id/merge_requests' do
    def update_merge_request(params)
      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user), params: params
    end

    context 'multiple assignees' do
      let(:other_user) { create(:user) }
      let(:params) do
        { assignee_ids: [user.id, other_user.id] }
      end

      context 'when licensed' do
        before do
          stub_licensed_features(multiple_merge_request_assignees: true)
        end

        it 'creates merge request with multiple assignees' do
          update_merge_request(params)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['assignees'].size).to eq(2)
          expect(json_response['assignees'].first['name']).to eq(user.name)
          expect(json_response['assignees'].second['name']).to eq(other_user.name)
          expect(json_response.dig('assignee', 'name')).to eq(user.name)
        end
      end

      context 'when not licensed' do
        before do
          stub_licensed_features(multiple_merge_request_assignees: false)
        end

        it 'creates merge request with a single assignee' do
          update_merge_request(params)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['assignees'].size).to eq(1)
          expect(json_response['assignees'].first['name']).to eq(user.name)
          expect(json_response.dig('assignee', 'name')).to eq(user.name)
        end
      end
    end

    context 'when updating existing approval rules' do
      let!(:rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1) }

      it 'is successful' do
        update_merge_request(
          title: "New title",
          approval_rules_attributes: [
            { id: rule.id, approvals_required: 2 }
          ]
        )

        expect(response).to have_gitlab_http_status(200)

        merge_request.reload

        expect(merge_request.approval_rules.size).to eq(1)
        expect(merge_request.approval_rules.first.approvals_required).to eq(2)
      end
    end
  end

  describe "POST /projects/:id/merge_requests" do
    def create_merge_request(args)
      defaults = {
          title: 'Test merge_request',
          source_branch: 'feature_conflict',
          target_branch: 'master',
          author: user,
          labels: 'label, label2',
          milestone_id: milestone.id
      }
      defaults = defaults.merge(args)
      post api("/projects/#{project.id}/merge_requests", user), params: defaults
    end

    context 'multiple assignees' do
      context 'when licensed' do
        before do
          stub_licensed_features(multiple_merge_request_assignees: true)
        end

        it 'creates merge request with multiple assignees' do
          create_merge_request(assignee_ids: [user.id, user2.id])

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['assignees'].size).to eq(2)
          expect(json_response['assignees'].first['name']).to eq(user.name)
          expect(json_response['assignees'].second['name']).to eq(user2.name)
          expect(json_response.dig('assignee', 'name')).to eq(user.name)
        end
      end

      context 'when not licensed' do
        before do
          stub_licensed_features(multiple_merge_request_assignees: false)
        end

        it 'creates merge request with a single assignee' do
          create_merge_request(assignee_ids: [user.id, user2.id])

          expect(response).to have_gitlab_http_status(201)
          expect(json_response['assignees'].size).to eq(1)
          expect(json_response['assignees'].first['name']).to eq(user.name)
          expect(json_response.dig('assignee', 'name')).to eq(user.name)
        end
      end
    end

    context 'between branches projects' do
      it "returns merge_request" do
        create_merge_request(squash: true)

        expect(response).to have_gitlab_http_status(201)
        expect(json_response['title']).to eq('Test merge_request')
        expect(json_response['labels']).to eq(%w(label label2))
        expect(json_response['milestone']['id']).to eq(milestone.id)
        expect(json_response['squash']).to be_truthy
        expect(json_response['force_remove_source_branch']).to be_falsy
      end

      context 'the approvals_before_merge param' do
        context 'when the target project has disable_overriding_approvers_per_merge_request set to true' do
          before do
            project.update(disable_overriding_approvers_per_merge_request: true)
            create_merge_request(approvals_before_merge: 1)
          end

          it 'does not set approvals_before_merge' do
            expect(json_response['approvals_before_merge']).to eq(nil)
          end
        end

        context 'when the target project has disable_overriding_approvers_per_merge_request set to false' do
          before do
            project.update(approvals_before_merge: 0)
            create_merge_request(approvals_before_merge: 1)
          end

          it 'sets approvals_before_merge' do
            expect(response).to have_gitlab_http_status(201)
            expect(json_response['message']).to eq(nil)
            expect(json_response['approvals_before_merge']).to eq(1)
          end
        end
      end
    end
  end

  describe "PUT /projects/:id/merge_requests/:merge_request_iid/merge" do
    it 'returns 405 if merge request was not approved' do
      project.add_developer(create(:user))
      project.update(approvals_before_merge: 1)

      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user)

      expect(response).to have_gitlab_http_status(406)
      expect(json_response['message']).to eq('Branch cannot be merged')
    end

    it 'returns 200 if merge request was approved' do
      approver = create(:user)
      project.add_developer(approver)
      project.update(approvals_before_merge: 1)
      merge_request.approvals.create(user: approver)

      put api("/projects/#{project.id}/merge_requests/#{merge_request.iid}/merge", user)

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe "DELETE /projects/:id/merge_requests/:merge_request_iid" do
    context "when the merge request is on the merge train" do
      let!(:merge_request) { create(:merge_request, :on_train, source_project: project, target_project: project) }

      before do
        ::MergeRequests::MergeToRefService.new(merge_request.project, merge_request.merge_user, target_ref: merge_request.train_ref_path)
                                          .execute(merge_request)
      end

      it 'removes train ref' do
        expect do
          delete api("/projects/#{project.id}/merge_requests/#{merge_request.iid}", user)
        end.to change { project.repository.ref_exists?(merge_request.train_ref_path) }.from(true).to(false)
      end
    end
  end

  context 'when authenticated' do
    def expect_response_contain_exactly(*items)
      expect(response).to have_gitlab_http_status(200)
      expect(json_response.length).to eq(items.size)
      expect(json_response.map { |element| element['id'] }).to contain_exactly(*items.map(&:id))
    end

    let!(:merge_request_with_approver) do
      create(:merge_request_with_approver, :simple, author: user, source_project: project, target_project: project, source_branch: 'other-branch')
    end

    context 'filter merge requests by assignee ID' do
      let!(:merge_request2) do
        create(:merge_request, :simple, assignees: [user2], source_project: project, target_project: project, source_branch: 'other-branch-2')
      end

      it 'returns merge requests with given assignee ID' do
        get api('/merge_requests', user), params: { assignee_id: user2.id }

        expect_response_contain_exactly(merge_request, merge_request2)
      end
    end

    context 'filter merge requests by approver IDs' do
      before do
        get api('/merge_requests', user), params: { approver_ids: approvers_param, scope: :all }
      end

      context 'with specified approver id' do
        let(:approvers_param) { [merge_request_with_approver.approvers.first.user_id] }

        it 'returns an array of merge requests which have specified the user as an approver' do
          expect_response_contain_exactly(merge_request_with_approver)
        end
      end

      context 'with specified None as a param' do
        let(:approvers_param) { 'None' }

        it 'returns an array of merge requests with no approvers' do
          expect_response_contain_exactly(merge_request)
        end
      end

      context 'with specified Any as a param' do
        let(:approvers_param) { 'Any' }

        it 'returns an array of merge requests with any approver' do
          expect_response_contain_exactly(merge_request_with_approver)
        end
      end

      context 'with any other string as a param' do
        let(:approvers_param) { 'any-other-string' }

        it 'returns a validation error' do
          expect(response).to have_gitlab_http_status(400)
          expect(json_response['error']).to eq("approver_ids should be an array, 'None' or 'Any'")
        end
      end
    end
  end
end
