# frozen_string_literal: true

require 'spec_helper'

describe Projects::Security::VulnerabilitiesController do
  let(:project) { create(:project) }
  let(:params) { { project_id: project, namespace_id: project.creator } }

  it_behaves_like VulnerabilitiesActions do
    let(:vulnerable) { project }
    let(:vulnerable_params) { params }
  end

  it_behaves_like SecurityDashboardsPermissions do
    let(:vulnerable) { project }
    let(:security_dashboard_action) { get :index, params: params, format: :json }
  end
end
