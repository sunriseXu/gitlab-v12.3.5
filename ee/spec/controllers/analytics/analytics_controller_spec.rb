# frozen_string_literal: true

require 'spec_helper'

describe Analytics::AnalyticsController do
  include AnalyticsHelpers

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    describe 'redirects to the first enabled analytics page' do
      it 'redirects to cycle analytics' do
        disable_all_analytics_feature_flags
        stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)

        get :index

        expect(response).to redirect_to(analytics_cycle_analytics_path)
      end

      it 'redirects to productivity analytics' do
        disable_all_analytics_feature_flags
        stub_feature_flags(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => true)

        get :index

        expect(response).to redirect_to(analytics_productivity_analytics_path)
      end
    end

    it 'renders 404 all the analytics feature flags are disabled' do
      disable_all_analytics_feature_flags

      get :index

      expect(response).to have_gitlab_http_status(404)
    end
  end
end
