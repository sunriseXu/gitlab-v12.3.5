# frozen_string_literal: true

require "spec_helper"

describe EE::UserCalloutsHelper do
  describe '.render_enable_hashed_storage_warning' do
    context 'when we should show the enable warning' do
      it 'renders the enable warning' do
        expect(helper).to receive(:show_enable_hashed_storage_warning?).and_return(true)

        expect(helper).to receive(:render_flash_user_callout)
          .with(:warning,
            /Please enable and migrate to hashed/,
            EE::UserCalloutsHelper::GEO_ENABLE_HASHED_STORAGE)

        helper.render_enable_hashed_storage_warning
      end
    end

    context 'when we should not show the enable warning' do
      it 'does not render the enable warning' do
        expect(helper).to receive(:show_enable_hashed_storage_warning?).and_return(false)

        expect(helper).not_to receive(:render_flash_user_callout)

        helper.render_enable_hashed_storage_warning
      end
    end
  end

  describe '.render_migrate_hashed_storage_warning' do
    context 'when we should show the migrate warning' do
      it 'renders the migrate warning' do
        expect(helper).to receive(:show_migrate_hashed_storage_warning?).and_return(true)

        expect(helper).to receive(:render_flash_user_callout)
          .with(:warning,
            /Please migrate all existing projects/,
            EE::UserCalloutsHelper::GEO_MIGRATE_HASHED_STORAGE)

        helper.render_migrate_hashed_storage_warning
      end
    end

    context 'when we should not show the migrate warning' do
      it 'does not render the migrate warning' do
        expect(helper).to receive(:show_migrate_hashed_storage_warning?).and_return(false)

        expect(helper).not_to receive(:render_flash_user_callout)

        helper.render_migrate_hashed_storage_warning
      end
    end
  end

  describe '.show_enable_hashed_storage_warning?' do
    subject { helper.show_enable_hashed_storage_warning? }
    let(:user) { create(:user) }

    context 'when hashed storage is disabled' do
      before do
        stub_application_setting(hashed_storage_enabled: false)
        expect(helper).to receive(:current_user).and_return(user)
      end

      context 'when the enable warning has not been dismissed' do
        it { is_expected.to be_truthy }
      end

      context 'when the enable warning was dismissed' do
        before do
          create(:user_callout, user: user, feature_name: described_class::GEO_ENABLE_HASHED_STORAGE)
        end

        it { is_expected.to be_falsy }
      end
    end

    context 'when hashed storage is enabled' do
      before do
        stub_application_setting(hashed_storage_enabled: true)
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '.show_migrate_hashed_storage_warning?' do
    subject { helper.show_migrate_hashed_storage_warning? }
    let(:user) { create(:user) }

    context 'when hashed storage is disabled' do
      before do
        stub_application_setting(hashed_storage_enabled: false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when hashed storage is enabled' do
      before do
        stub_application_setting(hashed_storage_enabled: true)
        expect(helper).to receive(:current_user).and_return(user)
      end

      context 'when the enable warning has not been dismissed' do
        context 'when there is a project in non-hashed-storage' do
          before do
            create(:project, :legacy_storage)
          end

          it { is_expected.to be_truthy }
        end

        context 'when there are NO projects in non-hashed-storage' do
          it { is_expected.to be_falsy }
        end
      end

      context 'when the enable warning was dismissed' do
        before do
          create(:user_callout, user: user, feature_name: described_class::GEO_MIGRATE_HASHED_STORAGE)
        end

        it { is_expected.to be_falsy }
      end
    end
  end

  describe '.show_canary_deployment_callout?' do
    let(:project) { build(:project) }

    subject { helper.show_canary_deployment_callout?(project) }

    before do
      allow(helper).to receive(:show_promotions?).and_return(true)
    end

    context 'when user needs to upgrade to canary deployments' do
      before do
        allow(project).to receive(:feature_available?).with(:deploy_board).and_return(false)
      end

      context 'when user has dismissed' do
        before do
          allow(helper).to receive(:user_dismissed?).and_return(true)
        end

        it { is_expected.to be_falsey }
      end

      context 'when user has not dismissed' do
        before do
          allow(helper).to receive(:user_dismissed?).and_return(false)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when user already has access to canary deployments' do
      before do
        allow(project).to receive(:feature_available?).with(:deploy_board).and_return(true)
        allow(helper).to receive(:user_dismissed?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#render_dashboard_gold_trial' do
    using RSpec::Parameterized::TableSyntax

    set(:namespace) { create(:namespace) }
    set(:gold_plan) { create(:gold_plan) }
    let(:user) { namespace.owner }

    where(:show_gold_trial?, :user_default_dashboard?, :has_no_trial_or_gold_plan?, :should_render?) do
      true  | true  | true  | true
      true  | true  | false | false
      true  | false | true  | false
      false | true  | true  | false
      true  | false | false | false
      false | false | true  | false
      false | true  | false | false
      false | false | false | false
    end

    with_them do
      before do
        allow(helper).to receive(:show_gold_trial?) { show_gold_trial? }
        allow(helper).to receive(:user_default_dashboard?) { user_default_dashboard? }
        namespace.update(plan: gold_plan) unless has_no_trial_or_gold_plan?
      end

      it do
        if should_render?
          expect(helper).to receive(:render).with('shared/gold_trial_callout_content')
        else
          expect(helper).not_to receive(:render)
        end

        helper.render_dashboard_gold_trial(user)
      end
    end
  end

  describe '#render_billings_gold_trial' do
    using RSpec::Parameterized::TableSyntax

    set(:namespace) { create(:namespace) }
    set(:silver_plan) { create(:silver_plan) }
    set(:gold_plan) { create(:gold_plan) }
    let(:user) { namespace.owner }

    where(:show_gold_trial?, :gold_plan?, :free_plan?, :should_render?) do
      true  | false | false | true
      true  | false | true  | true
      true  | true  | true  | false
      true  | true  | false | false
      false | true  | true  | false
      false | false | true  | false
      false | true  | false | false
      false | false | false | false
    end

    with_them do
      before do
        allow(helper).to receive(:show_gold_trial?) { show_gold_trial? }
        namespace.update(plan: gold_plan) if gold_plan?
        namespace.update(plan: silver_plan) if !gold_plan? && !free_plan?
      end

      it do
        if should_render?
          expect(helper).to receive(:render).with('shared/gold_trial_callout_content', is_dismissable: !free_plan?, callout: UserCalloutsHelper::GOLD_TRIAL_BILLINGS)
        else
          expect(helper).not_to receive(:render)
        end

        helper.render_billings_gold_trial(user, namespace)
      end
    end
  end
end
