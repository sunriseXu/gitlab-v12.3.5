# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageData do
  describe '#data' do
    # using Array.new to create a different creator User for each of the projects
    let(:projects) { Array.new(3) { create(:project, creator: create(:user, group_view: :security_dashboard)) } }
    let(:count_data) { subject[:counts] }

    let!(:board) { create(:board, project: projects[0]) }

    before do
      projects.last.creator.block # to get at least one non-active User

      pipeline = create(:ci_pipeline, project: projects[0])
      create(:ci_build, name: 'container_scanning', pipeline: pipeline)
      create(:ci_build, name: 'dast', pipeline: pipeline)
      create(:ci_build, name: 'dependency_scanning', pipeline: pipeline)
      create(:ci_build, name: 'license_management', pipeline: pipeline)
      create(:ci_build, name: 'sast', pipeline: pipeline)

      create(:prometheus_alert, project: projects[0])
      create(:prometheus_alert, project: projects[0])
      create(:prometheus_alert, project: projects[1])

      create(:package, project: projects[0])
      create(:package, project: projects[0])
      create(:package, project: projects[1])

      create(:project_tracing_setting, project: projects[0])
      create(:operations_feature_flag, project: projects[0])

      # for group_view testing
      create(:user) # user with group_view = NULL (should be counted as having default value 'details')
      create(:user, group_view: :details)
    end

    subject { described_class.data }

    it 'gathers usage data' do
      expect(subject.keys).to include(*%i(
        historical_max_users
        license_add_ons
        license_plan
        license_expires_at
        license_starts_at
        license_user_count
        license_trial
        licensee
        license_md5
        license_id
        elasticsearch_enabled
        geo_enabled
      ))
    end

    it do
      is_expected.to include(design_management_designs_create: a_kind_of(Integer),
                             design_management_designs_update: a_kind_of(Integer),
                             design_management_designs_delete: a_kind_of(Integer))
    end

    it 'gathers usage counts' do
      expect(count_data[:boards]).to eq(1)
      expect(count_data[:projects]).to eq(3)

      expect(count_data.keys).to include(*%i(
        container_scanning_jobs
        dast_jobs
        dependency_list_usages_total
        dependency_scanning_jobs
        epics
        feature_flags
        geo_nodes
        ldap_group_links
        ldap_keys
        ldap_users
        license_management_jobs
        operations_dashboard
        pod_logs_usages_total
        projects_jira_dvcs_cloud_active
        projects_jira_dvcs_server_active
        projects_mirrored_with_pipelines_enabled
        projects_reporting_ci_cd_back_to_github
        projects_with_packages
        projects_with_prometheus_alerts
        projects_with_tracing_enabled
        sast_jobs
      ))

      expect(count_data[:projects_with_prometheus_alerts]).to eq(2)
      expect(count_data[:projects_with_packages]).to eq(2)
      expect(count_data[:feature_flags]).to eq(1)
    end

    it 'gathers deepest epic relationship level' do
      expect(count_data.keys).to include(:epics_deepest_relationship_level)
    end

    it 'gathers security products usage data' do
      expect(count_data[:container_scanning_jobs]).to eq(1)
      expect(count_data[:dast_jobs]).to eq(1)
      expect(count_data[:dependency_scanning_jobs]).to eq(1)
      expect(count_data[:license_management_jobs]).to eq(1)
      expect(count_data[:sast_jobs]).to eq(1)
    end

    it 'gathers group overview preferences usage data' do
      expect(subject[:counts][:user_preferences]).to eq(
        group_overview_details: User.active.count - 2, # we have exactly 2 active users with security dashboard set
        group_overview_security_dashboard: 2
      )
    end
  end

  describe '#features_usage_data_ee' do
    subject { described_class.features_usage_data_ee }

    it 'gathers feature usage data of EE' do
      expect(subject[:elasticsearch_enabled]).to eq(Gitlab::CurrentSettings.elasticsearch_search?)
      expect(subject[:geo_enabled]).to eq(Gitlab::Geo.enabled?)
    end
  end

  describe 'License edition names' do
    let(:ultimate) { create(:license, plan: 'ultimate') }
    let(:premium) { create(:license, plan: 'premium') }
    let(:starter) { create(:license, plan: 'starter') }
    let(:old) { create(:license, plan: 'other') }

    it 'have expected values' do
      expect(ultimate.edition).to eq('EEU')
      expect(premium.edition).to eq('EEP')
      expect(starter.edition).to eq('EES')
      expect(old.edition).to eq('EE')
    end
  end

  describe '#license_usage_data' do
    subject { described_class.license_usage_data }

    it 'gathers license data' do
      license = ::License.current

      expect(subject[:license_md5]).to eq(Digest::MD5.hexdigest(license.data))
      expect(subject[:license_id]).to eq(license.license_id)
      expect(subject[:historical_max_users]).to eq(::HistoricalData.max_historical_user_count)
      expect(subject[:licensee]).to eq(license.licensee)
      expect(subject[:license_user_count]).to eq(license.restricted_user_count)
      expect(subject[:license_starts_at]).to eq(license.starts_at)
      expect(subject[:license_expires_at]).to eq(license.expires_at)
      expect(subject[:license_add_ons]).to eq(license.add_ons)
      expect(subject[:license_trial]).to eq(license.trial?)
    end
  end

  describe '.service_desk_counts' do
    subject { described_class.service_desk_counts }

    before do
      Project.update_all(service_desk_enabled: true)
    end

    context 'when Service Desk is disabled' do
      it 'returns an empty hash' do
        stub_licensed_features(service_desk: false)

        expect(subject).to eq({})
      end
    end

    context 'when there is no license' do
      it 'returns an empty hash' do
        allow(License).to receive(:current).and_return(nil)

        expect(subject).to eq({})
      end
    end

    context 'when Service Desk is enabled' do
      let(:project) { create(:project) }

      it 'gathers Service Desk data' do
        create_list(:issue, 2, confidential: true, author: User.support_bot, project: project)

        stub_licensed_features(service_desk: true)
        allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).with(anything).and_return(true)

        expect(subject).to eq(service_desk_enabled_projects: 1,
                              service_desk_issues: 2)
      end
    end
  end

  describe 'code owner approval required' do
    before do
      create(:project, :archived, :requiring_code_owner_approval)
      create(:project, :requiring_code_owner_approval, pending_delete: true)
      create(:project, :requiring_code_owner_approval)
    end

    it 'counts the projects actively requiring code owner approval' do
      expect(described_class.system_usage_data[:counts][:projects_enforcing_code_owner_approval]).to eq(1)
    end
  end

  describe '#operations_dashboard_usage' do
    subject { described_class.operations_dashboard_usage }

    before do
      blocked_user = create(:user, :blocked, dashboard: 'operations')
      user_with_ops_dashboard = create(:user, dashboard: 'operations')

      create(:users_ops_dashboard_project, user: blocked_user)
      create(:users_ops_dashboard_project, user: user_with_ops_dashboard)
      create(:users_ops_dashboard_project, user: user_with_ops_dashboard)
      create(:users_ops_dashboard_project)
    end

    it 'gathers data on operations dashboard' do
      expect(subject.keys).to include(*%i(
        default_dashboard
        users_with_projects_added
      ))
    end

    it 'bases counts on active users' do
      expect(subject[:default_dashboard]).to eq(1)
      expect(subject[:users_with_projects_added]).to eq(2)
    end
  end

  describe 'count incident_issues' do
    let(:project) { create(:project) }

    subject { described_class.data.dig(:counts, :incident_issues) }

    before do
      create(:issue, project: project) # non incident issue
    end

    context 'when incident_management feature is available' do
      before do
        stub_licensed_features(incident_management: true)
      end

      context 'with incident issues' do
        before do
          create_list(:issue, 2, project: project, author: User.alert_bot)
        end

        it { is_expected.to eq(2) }
      end

      context 'without incident_issues' do
        it { is_expected.to eq(0) }

        it { expect { subject }.to change(User, :count).by(1) }
      end
    end

    context 'when incident_management feature is not available' do
      before do
        stub_licensed_features(incident_management: false)
      end

      it { is_expected.to eq(0) }

      it { expect { subject }.not_to change(User, :count) }
    end
  end
end
