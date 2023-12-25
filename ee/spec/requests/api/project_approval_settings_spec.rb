# frozen_string_literal: true

require 'spec_helper'

describe API::ProjectApprovalSettings do
  set(:group) { create(:group_with_members) }
  set(:user) { create(:user) }
  set(:user2) { create(:user) }
  set(:admin) { create(:user, :admin) }
  set(:project) { create(:project, :public, :repository, creator: user, namespace: user.namespace, only_allow_merge_if_pipeline_succeeds: false) }
  set(:approver) { create(:user) }

  describe 'GET /projects/:id/approval_settings' do
    let(:url) { "/projects/#{project.id}/approval_settings" }

    context 'when the request is correct' do
      let!(:rule) do
        rule = create(:approval_project_rule, name: 'security', project: project, approvals_required: 7)
        rule.users << approver
        rule
      end

      let(:developer) do
        user = create(:user)
        project.add_guest(user)
        user
      end

      it 'matches the response schema' do
        get api(url, developer)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('public_api/v4/project_approval_settings', dir: 'ee')

        json = json_response

        expect(json['rules'].size).to eq(1)

        rule = json['rules'].first

        expect(rule['approvals_required']).to eq(7)
        expect(rule['name']).to eq('security')
      end

      context 'private group filtering' do
        set(:private_group) { create :group, :private }

        before do
          rule.groups << private_group
        end

        it 'excludes private groups if user has no access' do
          get api(url, developer)

          json = json_response
          rule = json['rules'].first

          expect(rule['groups'].size).to eq(0)
        end

        it 'includes private groups if user has access' do
          private_group.add_owner(developer)

          get api(url, developer)

          json = json_response
          rule = json['rules'].first

          expect(rule['groups'].size).to eq(1)
        end
      end

      context 'report_approver rules' do
        let!(:report_approver_rule) do
          create(:approval_project_rule, :security_report, project: project)
        end

        it 'includes report_approver rules' do
          get api(url, developer)

          json = json_response

          expect(json['rules'].size).to eq(2)
          expect(json['rules'].map { |rule| rule['name'] }).to contain_exactly(rule.name, report_approver_rule.name)
        end
      end
    end
  end

  describe 'POST /projects/:id/approval_settings/rules' do
    let(:schema) { 'public_api/v4/project_approval_setting' }
    let(:url) { "/projects/#{project.id}/approval_settings/rules" }

    it_behaves_like 'an API endpoint for creating project approval rule'
  end

  describe 'PUT /projects/:id/approval_settings/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:schema) { 'public_api/v4/project_approval_setting' }
    let(:url) { "/projects/#{project.id}/approval_settings/rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for updating project approval rule'
  end

  describe 'DELETE /projects/:id/approval_settings/rules/:approval_rule_id' do
    let!(:approval_rule) { create(:approval_project_rule, project: project) }
    let(:url) { "/projects/#{project.id}/approval_settings/rules/#{approval_rule.id}" }

    it_behaves_like 'an API endpoint for deleting project approval rule'
  end
end
