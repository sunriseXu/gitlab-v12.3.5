require 'spec_helper'

describe API::Groups do
  set(:group) { create(:group) }
  set(:private_group) { create(:group, :private) }
  set(:project) { create(:project, group: group) }
  set(:user) { create(:user) }
  set(:another_user) { create(:user) }
  let(:admin) { create(:admin) }

  before do
    group.add_owner(user)
    group.ldap_group_links.create cn: 'ldap-group', group_access: Gitlab::Access::MAINTAINER, provider: 'ldap'
  end

  describe "GET /groups" do
    context "when authenticated as user" do
      it "returns ldap details" do
        get api("/groups", user)

        expect(json_response).to(
          satisfy_one { |group_json| group_json['ldap_cn'] == group.ldap_cn })
        expect(json_response).to(
          satisfy_one do |group_json|
            group_json['ldap_access'] == group.ldap_access
          end
        )

        expect(json_response).to(
          satisfy_one do |group_json|
            ldap_group_link = group_json['ldap_group_links'].first

            ldap_group_link['cn'] == group.ldap_cn &&
              ldap_group_link['group_access'] == group.ldap_access &&
              ldap_group_link['provider'] == 'ldap'
          end
        )
      end
    end
  end

  describe 'GET /groups/:id' do
    before do
      create(:ip_restriction, group: private_group)
      private_group.add_maintainer(user)
    end

    context 'when the group_ip_restriction feature is not available' do
      before do
        stub_licensed_features(group_ip_restriction: false)
      end

      it 'returns 200' do
        get api("/groups/#{private_group.id}", user)

        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'when the group_ip_restriction feature is available' do
      before do
        stub_licensed_features(group_ip_restriction: true)
      end

      it 'returns 404 for request from ip not in the range' do
        get api("/groups/#{private_group.id}", user)

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 200 for request from ip in the range' do
        get api("/groups/#{private_group.id}", user), headers: { 'REMOTE_ADDR' => '192.168.0.0' }

        expect(response).to have_gitlab_http_status(200)
      end
    end
  end

  describe 'PUT /groups/:id' do
    subject { put api("/groups/#{group.id}", user), params: params }

    context 'file_template_project_id' do
      let(:params) { { file_template_project_id: project.id } }

      it 'does not update file_template_project_id if unlicensed' do
        stub_licensed_features(custom_file_templates_for_namespace: false)

        expect { subject }.not_to change { group.reload.file_template_project_id }
        expect(response).to have_gitlab_http_status(200)
        expect(json_response).not_to have_key('file_template_project_id')
      end

      it 'updates file_template_project_id if licensed' do
        stub_licensed_features(custom_file_templates_for_namespace: true)

        expect { subject }.to change { group.reload.file_template_project_id }.to(project.id)
        expect(response).to have_gitlab_http_status(200)
        expect(json_response['file_template_project_id']).to eq(project.id)
      end
    end

    context 'shared_runners_minutes_limit' do
      let(:params) { { shared_runners_minutes_limit: 133 } }

      context 'when authenticated as the group owner' do
        it 'returns 200 if shared_runners_minutes_limit is not changing' do
          group.update(shared_runners_minutes_limit: 133)

          expect do
            put api("/groups/#{group.id}", user), params: { shared_runners_minutes_limit: 133 }
          end.not_to change { group.shared_runners_minutes_limit }

          expect(response).to have_gitlab_http_status(200)
        end
      end

      context 'when authenticated as the admin' do
        let(:user) { create(:admin) }

        it 'updates the group for shared_runners_minutes_limit' do
          expect { subject }.to(
            change { group.reload.shared_runners_minutes_limit }.from(nil).to(133))

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['shared_runners_minutes_limit']).to eq(133)
        end
      end
    end
  end

  describe "POST /groups" do
    context "when authenticated as user with group permissions" do
      it "creates an ldap_group_link if ldap_cn and ldap_access are supplied" do
        group_attributes = attributes_for(:group, ldap_cn: 'ldap-group', ldap_access: Gitlab::Access::DEVELOPER)
        expect { post api("/groups", admin), params: group_attributes }.to change { LdapGroupLink.count }.by(1)
      end

      context 'when shared_runners_minutes_limit is given' do
        context 'when the current user is not an admin' do
          it "does not create a group with shared_runners_minutes_limit" do
            group = attributes_for(:group, { shared_runners_minutes_limit: 133 })

            expect do
              post api("/groups", another_user), params: group
            end.not_to change { Group.count }

            expect(response).to have_gitlab_http_status(403)
          end
        end

        context 'when the current user is an admin' do
          it "creates a group with shared_runners_minutes_limit" do
            group = attributes_for(:group, { shared_runners_minutes_limit: 133 })

            expect do
              post api("/groups", admin), params: group
            end.to change { Group.count }.by(1)

            created_group = Group.find(json_response['id'])

            expect(created_group.shared_runners_minutes_limit).to eq(133)
            expect(response).to have_gitlab_http_status(201)
            expect(json_response['shared_runners_minutes_limit']).to eq(133)
          end
        end
      end
    end
  end

  describe 'POST /groups/:id/ldap_sync' do
    before do
      allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
    end

    context 'when the ldap_group_sync feature is available' do
      before do
        stub_licensed_features(ldap_group_sync: true)
      end

      context 'when authenticated as the group owner' do
        context 'when the group is ready to sync' do
          it 'returns 202 Accepted' do
            ldap_sync(group.id, user, :disable!)
            expect(response).to have_gitlab_http_status(202)
          end

          it 'queues a sync job' do
            expect { ldap_sync(group.id, user, :fake!) }.to change(LdapGroupSyncWorker.jobs, :size).by(1)
          end

          it 'sets the ldap_sync state to pending' do
            ldap_sync(group.id, user, :disable!)
            expect(group.reload.ldap_sync_pending?).to be_truthy
          end
        end

        context 'when the group is already pending a sync' do
          before do
            group.pending_ldap_sync!
          end

          it 'returns 202 Accepted' do
            ldap_sync(group.id, user, :disable!)
            expect(response).to have_gitlab_http_status(202)
          end

          it 'does not queue a sync job' do
            expect { ldap_sync(group.id, user, :fake!) }.not_to change(LdapGroupSyncWorker.jobs, :size)
          end

          it 'does not change the ldap_sync state' do
            expect do
              ldap_sync(group.id, user, :disable!)
            end.not_to change { group.reload.ldap_sync_status }
          end
        end

        it 'returns 404 for a non existing group' do
          ldap_sync(1328, user, :disable!)
          expect(response).to have_gitlab_http_status(404)
        end
      end

      context 'when authenticated as the admin' do
        it 'returns 202 Accepted' do
          ldap_sync(group.id, admin, :disable!)
          expect(response).to have_gitlab_http_status(202)
        end
      end

      context 'when authenticated as a non-owner user that can see the group' do
        it 'returns 403' do
          ldap_sync(group.id, another_user, :disable!)
          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'when authenticated as an user that cannot see the group' do
        it 'returns 404' do
          ldap_sync(private_group.id, user, :disable!)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'when the ldap_group_sync feature is not available' do
      before do
        stub_licensed_features(ldap_group_sync: false)
      end

      it 'returns 404 (same as CE would)' do
        ldap_sync(group.id, admin, :disable!)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe "GET /groups/:id/projects" do
    context "when authenticated as user" do
      let(:project_with_reports) { create(:project, :public, group: group) }
      let!(:project_without_reports) { create(:project, :public, group: group) }

      before do
        create(:ee_ci_job_artifact, :sast, project: project_with_reports)
      end

      subject { get api("/groups/#{group.id}/projects", user), params: { with_security_reports: true } }

      context 'when security dashboard is enabled for a group' do
        let(:group) { create(:group, plan: :gold_plan) } # overriding group from parent context

        before do
          stub_licensed_features(security_dashboard: true)
          enable_namespace_license_check!

          create(:gitlab_subscription, hosted_plan: group.plan, namespace: group)
        end

        it "returns only projects with security reports" do
          subject

          expect(json_response.map { |p| p['id'] }).to contain_exactly(project_with_reports.id)
        end
      end

      context 'when security dashboard is disabled for a group' do
        it "returns all projects regardless of the security reports" do
          subject

          # using `include` since other projects may be added to this group from different contexts
          expect(json_response.map { |p| p['id'] }).to include(project_with_reports.id, project_without_reports.id)
        end
      end
    end
  end

  def ldap_sync(group_id, user, sidekiq_testing_method)
    Sidekiq::Testing.send(sidekiq_testing_method) do
      post api("/groups/#{group_id}/ldap_sync", user)
    end
  end
end
