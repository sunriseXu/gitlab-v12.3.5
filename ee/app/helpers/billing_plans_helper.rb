# frozen_string_literal: true

module BillingPlansHelper
  def subscription_plan_info(plans_data, current_plan_code)
    plans_data.find { |plan| plan.code == current_plan_code }
  end

  def number_to_plan_currency(value)
    number_to_currency(value, unit: '$', strip_insignificant_zeros: true, format: "%u%n")
  end

  def current_plan?(plan)
    plan.purchase_link&.action == 'current_plan'
  end

  def plan_purchase_link(href, link_text)
    if href
      link_to link_text, href, class: 'btn btn-primary btn-inverted'
    else
      button_tag link_text, class: 'btn disabled'
    end
  end

  def new_gitlab_com_trial_url
    "#{EE::SUBSCRIPTIONS_URL}/trials/new?gl_com=true"
  end

  def subscription_plan_data_attributes(group, plan)
    return {} unless group

    {
      namespace_id: group.id,
      namespace_name: group.name,
      plan_upgrade_href: plan_upgrade_url(group, plan)
    }
  end

  def plan_upgrade_url(group, plan)
    return unless group && plan&.id

    "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/upgrade/#{plan.id}"
  end
end
