require 'spec_helper'

describe 'Billing plan pages', :feature do
  include StubRequests

  let(:user) { create(:user) }
  let(:namespace) { user.namespace }
  let(:free_plan) { create(:free_plan) }
  let(:bronze_plan) { create(:bronze_plan) }
  let(:gold_plan) { create(:gold_plan) }
  let(:plans_data) do
    JSON.parse(File.read(Rails.root.join('ee/spec/fixtures/gitlab_com_plans.json'))).map do |data|
      data.deep_symbolize_keys
    end
  end

  before do
    stub_full_request("#{EE::SUBSCRIPTIONS_URL}/gitlab_plans?plan=#{plan}")
      .to_return(status: 200, body: plans_data.to_json)
    stub_application_setting(check_namespace_plan: true)
    allow(Gitlab).to receive(:com?) { true }
    gitlab_sign_in(user)
  end

  def external_upgrade_url(namespace, plan)
    if Plan::PAID_HOSTED_PLANS.include?(plan.name)
      "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{namespace.id}/upgrade/#{plan.name}-external-id"
    end
  end

  context 'users profile billing page' do
    let(:page_path) { profile_billings_path }

    it_behaves_like 'billings gold trial callout'

    context 'on free' do
      let(:plan) { free_plan.name }

      let!(:subscription) do
        create(:gitlab_subscription, namespace: namespace, hosted_plan: nil, seats: 15)
      end

      before do
        visit page_path
      end

      it 'displays all plans' do
        page.within('.billing-plans') do
          panels = page.all('.card')

          expect(panels.length).to eq(plans_data.length)

          plans_data.each.with_index do |data, index|
            expect(panels[index].find('.card-header')).to have_content(data[:name])
          end
        end
      end

      it 'displays correct plan actions' do
        expected_actions = plans_data.map { |data| data.fetch(:purchase_link).fetch(:action) }
        plan_actions = page.all('.billing-plans .card .plan-action')
        expect(plan_actions.length).to eq(expected_actions.length)

        expected_actions.each_with_index do |expected_action, index|
          action = plan_actions[index]

          case expected_action
          when 'downgrade'
            expect(action).to have_content('Downgrade')
            expect(action).to have_css('.disabled')
          when 'current_plan'
            expect(action).to have_content('Current plan')
            expect(action).to have_css('.disabled')
          when 'upgrade'
            expect(action).to have_content('Upgrade')
            expect(action).not_to have_css('.disabled')
          end
        end
      end
    end

    context 'on bronze' do
      let(:plan) { bronze_plan.name }

      let!(:subscription) do
        create(:gitlab_subscription, namespace: namespace, hosted_plan: bronze_plan, seats: 15)
      end

      before do
        visit page_path
      end

      it 'displays header and actions' do
        page.within('.billing-plan-header') do
          expect(page).to have_content("#{user.username} you are currently using the Bronze plan.")

          expect(page).to have_css('.billing-plan-logo img')
        end

        page.within('.content') do
          expect(page).to have_link('Upgrade plan', href: external_upgrade_url(namespace, bronze_plan))
          expect(page).to have_content('downgrade your plan')
          expect(page).to have_link('Customer Support', href: EE::CUSTOMER_SUPPORT_URL)
        end
      end
    end

    context 'on gold' do
      let(:plan) { gold_plan.name }

      let!(:subscription) do
        create(:gitlab_subscription, namespace: namespace, hosted_plan: gold_plan, seats: 15)
      end

      before do
        visit page_path
      end

      it 'displays header and actions' do
        page.within('.billing-plan-header') do
          expect(page).to have_content("#{user.username} you are currently using the Gold plan.")

          expect(page).to have_css('.billing-plan-logo img')
        end

        page.within('.content') do
          expect(page).not_to have_link('Upgrade plan')
          expect(page).to have_content('downgrade your plan')
          expect(page).to have_link('Customer Support', href: EE::CUSTOMER_SUPPORT_URL)
        end
      end
    end
  end

  context 'group billing page' do
    let(:namespace) { create(:group) }
    let!(:group_member) { create(:group_member, :owner, group: namespace, user: user) }

    context 'top-most group' do
      let(:page_path) { group_billings_path(namespace) }

      it_behaves_like 'billings gold trial callout'

      context 'on bronze' do
        let(:plan) { bronze_plan.name }

        let!(:subscription) do
          create(:gitlab_subscription, namespace: namespace, hosted_plan: bronze_plan, seats: 15)
        end

        before do
          visit page_path
        end

        it 'displays plan header' do
          page.within('.billing-plan-header') do
            expect(page).to have_content("#{namespace.name} is currently using the Bronze plan")

            expect(page).to have_css('.billing-plan-logo .identicon')
          end
        end

        it 'does not display the billing plans table' do
          expect(page).not_to have_css('.billing-plans')
        end

        it 'displays subscription table', :js do
          expect(page).to have_selector('.js-subscription-table')
        end
      end
    end
  end

  context 'on sub-group' do
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }
    let(:group) { create(:group, plan: :bronze_plan) }
    let!(:group_member) { create(:group_member, :owner, group: group, user: user) }
    let(:subgroup1) { create(:group, parent: group, plan: :silver_plan) }
    let!(:subgroup1_member) { create(:group_member, :owner, group: subgroup1, user: user2) }
    let(:subgroup2) { create(:group, parent: subgroup1) }
    let!(:subgroup2_member) { create(:group_member, :owner, group: subgroup2, user: user3) }
    let(:page_path) { group_billings_path(subgroup2) }
    let(:namespace) { group }

    it_behaves_like 'billings gold trial callout'

    context 'on bronze' do
      let(:plan) { bronze_plan.name }

      let!(:subscription) do
        create(:gitlab_subscription, namespace: namespace, hosted_plan: bronze_plan, seats: 15)
      end

      before do
        visit page_path
      end

      it 'displays plan header' do
        page.within('.billing-plan-header') do
          expect(page).to have_content("#{subgroup2.full_name} is currently using the Bronze plan")
          expect(page).to have_css('.billing-plan-logo .identicon')
          expect(page.find('.btn-success')).to have_content('Manage plan')
        end

        expect(page).not_to have_css('.billing-plans')
      end
    end
  end

  context 'with unexpected JSON' do
    let(:plan) { 'free' }

    let(:plans_data) do
      [
        {
          name: "Superhero",
          price_per_month: 999.0,
          free: true,
          code: "not-found",
          price_per_year: 111.0,
          purchase_link: {
            action: "upgrade",
            href: "http://customers.test.host/subscriptions/new?plan_id=super_hero_id"
          },
          features: []
        }
      ]
    end

    before do
      expect_any_instance_of(EE::Namespace).to receive(:plan).at_least(:once).and_return(nil)
      visit profile_billings_path
    end

    it 'renders no header for missing plan' do
      expect(page).not_to have_css('.billing-plan-header')
    end

    it 'displays all plans' do
      page.within('.billing-plans') do
        panels = page.all('.card')
        expect(panels.length).to eq(plans_data.length)
        plans_data.each_with_index do |data, index|
          expect(panels[index].find('.card-header')).to have_content(data[:name])
        end
      end
    end
  end
end
