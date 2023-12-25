# frozen_string_literal: true

class TrialRegistrationsController < RegistrationsController
  extend ::Gitlab::Utils::Override

  before_action :check_if_gl_com
  before_action :check_if_improved_trials_enabled
  before_action :set_redirect_url, only: [:new]
  before_action :skip_confirmation, only: [:create]

  def create
    super do |new_user|
      new_user.system_hook_service.execute_hooks_for(new_user, :create) if new_user.persisted?
    end
  end

  def new
  end

  private

  def set_redirect_url
    store_location_for(:user, new_trial_url)
  end

  def skip_confirmation
    params[:user][:skip_confirmation] = true
  end

  override :sign_up_params
  def sign_up_params
    if params[:user]
      params.require(:user).permit(:first_name, :last_name, :username, :email, :password, :skip_confirmation, :email_opted_in)
    else
      {}
    end
  end

  def resource
    @resource ||= Users::BuildService.new(current_user, sign_up_params).execute(skip_authorization: true)
  end

  def check_if_improved_trials_enabled
    render_404 unless Feature.enabled?(:improved_trial_signup)
  end
end
