# frozen_string_literal: true

require 'spec_helper'

describe JiraConnect::SyncService do
  describe '#execute' do
    set(:project) { create(:project, :repository) }
    let(:branches) { [project.repository.find_branch('master')] }
    let(:commits) { project.commits_by(oids: %w[b83d6e3 5a62481]) }
    let(:merge_requests) { [create(:merge_request, source_project: project, target_project: project)] }

    subject do
      described_class.new(project).execute(commits: commits, branches: branches, merge_requests: merge_requests)
    end

    before do
      create(:jira_connect_subscription, namespace: project.namespace)
    end

    def expect_jira_client_call(return_value = { 'status': 'success' })
      expect_any_instance_of(Atlassian::JiraConnect::Client)
        .to receive(:store_dev_info).with(
          project: project,
          commits: commits,
          branches: [instance_of(Gitlab::Git::Branch)],
          merge_requests: merge_requests
        ).and_return(return_value)
    end

    def expect_log(type, message)
      expect(Gitlab::ProjectServiceLogger)
        .to receive(type).with(
          integration: 'JiraConnect',
          project_id: project.id,
          project_path: project.full_path,
          response: message
        )
    end

    it 'calls Atlassian::JiraConnect::Client#store_dev_info and logs the response' do
      expect_jira_client_call

      expect_log(:info, { 'status': 'success' })

      subject
    end

    context 'when request returns an error' do
      it 'logs the response as an error' do
        expect_jira_client_call({
          'errorMessages' => ['some error message']
        })

        expect_log(:error, { 'errorMessages' => ['some error message'] })

        subject
      end
    end
  end
end
