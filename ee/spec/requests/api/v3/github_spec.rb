require 'spec_helper'

describe API::V3::Github do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, creator: user) }
  let!(:project2) { create(:project, :repository, creator: user) }

  before do
    project.add_maintainer(user)
    project2.add_maintainer(user)
  end

  describe 'GET /orgs/:namespace/repos' do
    it 'returns an empty array' do
      group = create(:group)

      jira_get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end

    it 'returns 200 when namespace path include a dot' do
      group = create(:group, path: 'foo.bar')

      jira_get v3_api("/orgs/#{group.path}/repos", user)

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe 'GET /user/repos' do
    it 'returns an empty array' do
      jira_get v3_api('/user/repos', user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end
  end

  shared_examples_for 'Jira-specific mimicked GitHub endpoints' do
    describe 'GET /.../issues/:id/comments' do
      context 'when user has access to the merge request' do
        let(:merge_request) do
          create(:merge_request, source_project: project, target_project: project)
        end
        let!(:note) do
          create(:note, project: project, noteable: merge_request)
        end

        it 'returns an array of notes' do
          stub_licensed_features(jira_dev_panel_integration: true)

          jira_get v3_api("/repos/#{path}/issues/#{merge_request.id}/comments", user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(1)
        end
      end

      context 'when user has no access to the merge request' do
        let(:private_project) { create(:project, :private) }
        let(:merge_request) do
          create(:merge_request, source_project: private_project, target_project: private_project)
        end
        let!(:note) do
          create(:note, project: private_project, noteable: merge_request)
        end

        before do
          private_project.add_guest(user)
        end

        it 'returns 404' do
          stub_licensed_features(jira_dev_panel_integration: true)

          jira_get v3_api("/repos/#{path}/issues/#{merge_request.id}/comments", user)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    describe 'GET /.../pulls/:id/commits' do
      it 'returns an empty array' do
        jira_get v3_api("/repos/#{path}/pulls/xpto/commits", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to eq([])
      end
    end

    describe 'GET /.../pulls/:id/comments' do
      it 'returns an empty array' do
        jira_get v3_api("/repos/#{path}/pulls/xpto/comments", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to eq([])
      end
    end
  end

  # Here we test that using /-/jira as namespace/project still works,
  # since that is how old Jira setups will talk to us
  context 'old /-/jira endpoints' do
    it_behaves_like 'Jira-specific mimicked GitHub endpoints' do
      let(:path) { '-/jira' }
    end

    it 'returns an empty Array for events' do
      jira_get v3_api('/repos/-/jira/events', user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to eq([])
    end
  end

  context 'new :namespace/:project jira endpoints' do
    it_behaves_like 'Jira-specific mimicked GitHub endpoints' do
      let(:path) { "#{project.namespace.path}/#{project.path}" }
    end

    describe 'GET /users/:username' do
      let!(:user1) { create(:user, username: 'jane.porter') }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      context 'user exists' do
        it 'responds with the expected user' do
          jira_get v3_api("/users/#{user.username}", user)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to match_response_schema('entities/github/user', dir: 'ee')
        end
      end

      context 'user does not exist' do
        it 'responds with the expected status' do
          jira_get v3_api('/users/unknown_user_name', user)

          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'no rights to request user lists' do
        let(:unauthorized_user) { create(:user) }

        before do
          expect(Ability).to receive(:allowed?).with(unauthorized_user, :read_users_list, :global).and_return(false)
          expect(Ability).to receive(:allowed?).at_least(:once).and_call_original
        end

        it 'responds with forbidden' do
          jira_get v3_api("/users/#{user.username}", unauthorized_user)

          expect(response).to have_gitlab_http_status(403)
        end
      end
    end

    describe 'GET events' do
      let(:group) { create(:group) }
      let(:project) { create(:project, :empty_repo, path: 'project.with.dot', group: group) }
      let(:events_path) { "/repos/#{group.path}/#{project.path}/events" }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      context 'if there are no merge requests' do
        it 'returns an empty array' do
          jira_get v3_api(events_path, user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to eq([])
        end
      end

      context 'if there is a merge request' do
        let!(:merge_request) { create(:merge_request, source_project: project, target_project: project, author: user) }

        it 'returns an event' do
          jira_get v3_api(events_path, user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(1)
        end
      end

      context 'if there are more merge requests' do
        let!(:merge_request) { create(:merge_request, id: 10000, source_project: project, target_project: project, author: user) }
        let!(:merge_request2) { create(:merge_request, id: 10001, source_project: project, source_branch: generate(:branch), target_project: project, author: user) }

        it 'returns the expected amount of events' do
          jira_get v3_api(events_path, user)

          expect(response).to have_gitlab_http_status(200)
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(2)
        end

        it 'ensures each event has a unique id' do
          jira_get v3_api(events_path, user)

          ids = json_response.map { |event| event['id'] }.uniq
          expect(ids.size).to eq(2)
        end
      end
    end
  end

  describe 'repo pulls' do
    let(:assignee) { create(:user) }
    let(:assignee2) { create(:user) }
    let!(:merge_request) do
      create(:merge_request, source_project: project, target_project: project, author: user, assignees: [assignee])
    end
    let!(:merge_request_2) do
      create(:merge_request, source_project: project2, target_project: project2, author: user, assignees: [assignee, assignee2])
    end

    describe 'GET /-/jira/pulls' do
      it 'returns an array of merge requests with github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        jira_get v3_api('/repos/-/jira/pulls', user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(2)
        expect(response).to match_response_schema('entities/github/pull_requests', dir: 'ee')
      end
    end

    describe 'GET /repos/:namespace/:project/pulls' do
      it 'returns an array of merge requests for the proper project in github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/pulls", user)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(1)
        expect(response).to match_response_schema('entities/github/pull_requests', dir: 'ee')
      end
    end

    describe 'GET /repos/:namespace/:project/pulls/:id' do
      it 'returns the requested merge request in github format' do
        stub_licensed_features(jira_dev_panel_integration: true)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/pulls/#{merge_request.id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('entities/github/pull_request', dir: 'ee')
      end
    end
  end

  describe 'GET /users/:namespace/repos' do
    let(:group) { create(:group, name: 'foo') }

    def expect_project_under_namespace(projects, namespace, user)
      jira_get v3_api("/users/#{namespace.path}/repos", user)

      expect(response).to have_gitlab_http_status(200)
      expect(response).to include_pagination_headers
      expect(response).to match_response_schema('entities/github/repositories', dir: 'ee')

      projects.each do |project|
        hash = json_response.find do |hash|
          hash['name'] == ::Gitlab::Jira::Dvcs.encode_project_name(project)
        end

        raise "Project #{project.full_path} not present in response" if hash.nil?

        expect(hash['owner']['login']).to eq(namespace.path)
      end
      expect(json_response.size).to eq(projects.size)
    end

    context 'when instance admin' do
      let(:project) { create(:project, group: group) }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([project], group, create(:user, :admin))
      end
    end

    context 'group namespace' do
      let(:project) { create(:project, group: group) }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
        group.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([project], group, user)
      end
    end

    context 'nested group namespace' do
      let(:group) { create(:group, :nested) }
      let!(:parent_group_project) { create(:project, group: group.parent, name: 'parent_group_project') }
      let!(:child_group_project) { create(:project, group: group, name: 'child_group_project') }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
        group.parent.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([parent_group_project, child_group_project], group.parent, user)
      end
    end

    context 'user namespace' do
      let(:project) { create(:project, namespace: user.namespace) }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      it 'returns an array of projects belonging to user namespace with github format' do
        expect_project_under_namespace([project], user.namespace, user)
      end
    end

    context 'namespace path includes a dot' do
      let(:project) { create(:project, group: group) }
      let(:group) { create(:group, name: 'foo.bar') }

      before do
        stub_licensed_features(jira_dev_panel_integration: true)
        group.add_maintainer(user)
      end

      it 'returns an array of projects belonging to group with github format' do
        expect_project_under_namespace([project], group, user)
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        jira_get v3_api('/users/foo/repos', nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    it 'filters unlicensed namespace projects' do
      licensed_project = create(:project, :empty_repo, group: group)
      licensed_project.add_reporter(user)

      create(:gitlab_subscription, :silver, namespace: licensed_project.namespace)

      stub_licensed_features(jira_dev_panel_integration: true)
      stub_application_setting_on_object(project, should_check_namespace_plan: true)
      stub_application_setting_on_object(licensed_project, should_check_namespace_plan: true)

      expect_project_under_namespace([licensed_project], group, user)
    end

    context 'namespace does not exist' do
      it 'responds with not found status' do
        stub_licensed_features(jira_dev_panel_integration: true)

        jira_get v3_api('/users/noo/repos', user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /repos/:namespace/:project/branches' do
    context 'authenticated' do
      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      context 'updating project feature usage' do
        it 'counts Jira Cloud integration as enabled' do
          user_agent = 'Jira DVCS Connector Vertigo/4.42.0'

          Timecop.freeze do
            jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user), user_agent

            expect(project.reload.jira_dvcs_cloud_last_sync_at).to be_like_time(Time.now)
          end
        end

        it 'counts Jira Server integration as enabled' do
          user_agent = 'Jira DVCS Connector/3.2.4'

          Timecop.freeze do
            jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user), user_agent

            expect(project.reload.jira_dvcs_server_last_sync_at).to be_like_time(Time.now)
          end
        end
      end

      it 'returns an array of project branches with github format' do
        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an(Array)

        expect(response).to match_response_schema('entities/github/branches', dir: 'ee')
      end

      it 'returns 200 when project path include a dot' do
        project.update!(path: 'foo.bar')

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns 200 when namespace path include a dot' do
        group = create(:group, path: 'foo.bar')
        project = create(:project, :repository, group: group)
        project.add_reporter(user)

        jira_get v3_api("/repos/#{group.path}/#{project.path}/branches", user)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        stub_licensed_features(jira_dev_panel_integration: true)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'unauthorized' do
      it 'returns 404 when not licensed' do
        stub_licensed_features(jira_dev_panel_integration: false)
        unauthorized_user = create(:user)
        project.add_reporter(unauthorized_user)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/branches", unauthorized_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET /repos/:namespace/:project/commits/:sha' do
    let(:commit) { project.repository.commit }
    let(:commit_id) { commit.id }

    context 'authenticated' do
      before do
        stub_licensed_features(jira_dev_panel_integration: true)
      end

      it 'returns commit with github format' do
        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('entities/github/commit', dir: 'ee')
      end

      it 'returns 200 when project path include a dot' do
        project.update!(path: 'foo.bar')

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(200)
      end

      it 'returns 200 when namespace path include a dot' do
        group = create(:group, path: 'foo.bar')
        project = create(:project, :repository, group: group)
        project.add_reporter(user)

        jira_get v3_api("/repos/#{group.path}/#{project.path}/commits/#{commit_id}", user)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'unauthenticated' do
      it 'returns 401' do
        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}", nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context 'unauthorized' do
      it 'returns 404 when lower access level' do
        unauthorized_user = create(:user)
        project.add_guest(unauthorized_user)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}",
                   unauthorized_user)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 404 when not licensed' do
        stub_licensed_features(jira_dev_panel_integration: false)
        unauthorized_user = create(:user)
        project.add_reporter(unauthorized_user)

        jira_get v3_api("/repos/#{project.namespace.path}/#{project.path}/commits/#{commit_id}",
                   unauthorized_user)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  def jira_get(path, user_agent = 'Jira DVCS Connector/3.2.4')
    get path, headers: { 'User-Agent' => user_agent }
  end

  def v3_api(path, user = nil, personal_access_token: nil, oauth_access_token: nil)
    api(
      path,
      user,
      version: 'v3',
      personal_access_token: personal_access_token,
      oauth_access_token: oauth_access_token
    )
  end
end
