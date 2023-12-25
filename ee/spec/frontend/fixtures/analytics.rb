# frozen_string_literal: true
require 'spec_helper'

describe 'Analytics (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  let(:group) { create(:group)}
  let(:project) { create(:project, :repository, namespace: group) }
  let(:user) { create(:user, :admin) }
  let(:issue) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:milestone) { create(:milestone, project: project) }
  let(:mr) { create_merge_request_closing_issue(user, project, issue, commit_message: "References #{issue.to_reference}") }
  let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: mr.source_branch, sha: mr.source_branch_sha, head_pipeline_of: mr) }
  let(:build) { create(:ci_build, :success, pipeline: pipeline, author: user) }

  let!(:issue_1) { create(:issue, project: project, created_at: 5.days.ago) }
  let!(:issue_2) { create(:issue, project: project, created_at: 4.days.ago) }
  let!(:issue_3) { create(:issue, project: project, created_at: 3.days.ago) }

  let!(:mr_1) { create_merge_request_closing_issue(user, project, issue_1) }
  let!(:mr_2) { create_merge_request_closing_issue(user, project, issue_2) }
  let!(:mr_3) { create_merge_request_closing_issue(user, project, issue_3) }

  def prepare_cycle_analytics_data
    group.add_maintainer(user)
    project.add_maintainer(user)

    create_cycle(user, project, issue, mr, milestone, pipeline)
    create_cycle(user, project, issue_2, mr_2, milestone, pipeline)

    create_commit_referencing_issue(issue_1)
    create_commit_referencing_issue(issue_2)

    create_merge_request_closing_issue(user, project, issue_1)
    create_merge_request_closing_issue(user, project, issue_2)

    merge_merge_requests_closing_issue(user, project, issue_3)

    deploy_master(user, project, environment: 'staging')
    deploy_master(user, project)
  end

  before(:all) do
    clean_frontend_fixtures('analytics/')
  end

  describe Groups::CycleAnalytics::EventsController, type: :controller do
    using RSpec::Parameterized::TableSyntax
    render_views

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      prepare_cycle_analytics_data

      sign_in(user)
    end

    default_stages = %w[issue plan review code test staging production]

    default_stages.each do |endpoint|
      it "cycle_analytics/events/#{endpoint}.json" do
        get endpoint, params: { group_id: group, format: :json }

        expect(response).to be_successful
      end
    end
  end

  describe Groups::CycleAnalyticsController, type: :controller do
    render_views

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      prepare_cycle_analytics_data

      sign_in(user)
    end

    it 'cycle_analytics/mock_data.json' do
      get(:show, params: {
        group_id: group.name,
        cycle_analytics: { start_date: 30 }
      }, format: :json)

      expect(response).to be_successful
    end
  end
end
