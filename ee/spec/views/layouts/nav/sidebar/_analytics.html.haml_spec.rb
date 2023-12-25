# frozen_string_literal: true

require 'spec_helper'

describe 'layouts/nav/sidebar/_analytics' do
  include AnalyticsHelpers

  it_behaves_like 'has nav sidebar'

  context 'top-level items' do
    context 'when feature flags are enabled' do
      it 'has `Analytics` link' do
        stub_feature_flags(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => true)

        render

        expect(rendered).to have_content('Analytics')
        expect(rendered).to include(analytics_root_path)
        expect(rendered).to match(/<use xlink:href=".+?icons-.+?#log">/)
      end

      it 'has `Productivity Analytics` link' do
        stub_feature_flags(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => true)

        render

        expect(rendered).to have_content('Productivity Analytics')
        expect(rendered).to include(analytics_productivity_analytics_path)
        expect(rendered).to match(/<use xlink:href=".+?icons-.+?#comment">/)
      end

      it 'has `Cycle Analytics` link' do
        stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)

        render

        expect(rendered).to have_content('Cycle Analytics')
        expect(rendered).to include(analytics_cycle_analytics_path)
        expect(rendered).to match(/<use xlink:href=".+?icons-.+?#repeat">/)
      end
    end

    context 'when feature flags are disabled' do
      it 'no analytics links are rendered' do
        disable_all_analytics_feature_flags

        expect(rendered).not_to have_content('Productivity Analytics')
        expect(rendered).not_to have_content('Cycle Analytics')
      end
    end
  end
end
