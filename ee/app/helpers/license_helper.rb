# frozen_string_literal: true

module LicenseHelper
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::UrlHelper

  delegate :new_admin_license_path, to: 'Gitlab::Routing.url_helpers'

  def active_user_count
    User.active.count
  end

  def guest_user_count
    active_user_count - User.active.excluding_guests.count
  end

  def max_historical_user_count
    HistoricalData.max_historical_user_count
  end

  def current_active_user_count
    License.current&.current_active_users_count || 0
  end

  def license_message(signed_in: signed_in?, is_admin: current_user&.admin?)
    return unless current_license
    return unless signed_in
    return unless (is_admin && current_license.notify_admins?) || current_license.notify_users?

    is_trial = current_license.trial?
    message = ["Your #{'trial ' if is_trial}license"]

    message << expiration_message

    message << link_to('Buy now!', ::EE::SUBSCRIPTIONS_PLANS_URL, target: '_blank') if is_trial

    if current_license.expired? && current_license.will_block_changes?
      message << 'Pushing code and creation of issues and merge requests'

      message << block_changes_message

      message <<

        if is_admin
          'Upload a new license in the admin area'
        else
          'Ask an admin to upload a new license'
        end

      message << 'to'
      message << (current_license.block_changes? ? 'restore' : 'ensure uninterrupted')
      message << 'service.'
    end

    message.join(' ').html_safe
  end

  def expiration_message
    if current_license.expired?
      "expired on #{current_license.expires_at}."
    else
      "will expire in #{pluralize(current_license.remaining_days, 'day')}."
    end
  end

  def block_changes_message
    if current_license.block_changes?
      'has been disabled.'
    else
      "will be disabled on #{current_license.block_changes_at}."
    end
  end

  def seats_calculation_message
    if current_license&.exclude_guests_from_active_count?
      content_tag :p do
        "Users with a Guest role or those who don't belong to a Project or Group will not use a seat from your license."
      end
    end
  end

  def current_license
    return @current_license if defined?(@current_license)

    @current_license = License.current
  end

  def new_trial_url
    return_to_url = CGI.escape(Gitlab.config.gitlab.url)
    uri = URI.parse(::EE::SUBSCRIPTIONS_URL)
    uri.path = '/trials/new'
    uri.query = "return_to=#{return_to_url}&id=#{Base64.strict_encode64(current_user.email)}"
    uri.to_s
  end

  def upgrade_plan_url
    group = @project&.group || @group
    if group
      group_billings_path(group)
    else
      profile_billings_path
    end
  end

  def show_promotions?(selected_user = current_user)
    return false unless selected_user

    if Gitlab::CurrentSettings.current_application_settings
      .should_check_namespace_plan?
      true
    else
      license = License.current
      license.nil? || license.expired?
    end
  end

  def show_advanced_search_promotion?
    !Gitlab::CurrentSettings.should_check_namespace_plan? && show_promotions? && show_callout?('promote_advanced_search_dismissed') && !License.feature_available?(:elastic_search)
  end

  def license_app_data
    { data: { active_user_count: active_user_count,
              guest_user_count: guest_user_count,
              licenses_path: api_licenses_url,
              delete_license_path: api_license_url(id: ':id'),
              new_license_path: new_admin_license_path, download_license_path: download_admin_license_path } }
  end

  def api_licenses_url
    expose_url(api_v4_licenses_path)
  end

  def api_license_url(args)
    expose_url(api_v4_license_path(args))
  end

  extend self
end
