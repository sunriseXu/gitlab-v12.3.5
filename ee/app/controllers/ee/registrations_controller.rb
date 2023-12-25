# frozen_string_literal: true

module EE
  module RegistrationsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    private

    override :user_created_message
    def user_created_message(confirmed: false)
      experiments = "experiment_growth_recaptcha?#{show_recaptcha_sign_up?}"

      super(confirmed: confirmed) + ", experiments:#{experiments}"
    end

    def sign_up_params
      clean_params = params.require(:user).permit(:username, :email, :email_confirmation, :name, :password, :email_opted_in)

      if clean_params[:email_opted_in] == '1'
        clean_params[:email_opted_in_ip] = request.remote_ip
        clean_params[:email_opted_in_source_id] = User::EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM
        clean_params[:email_opted_in_at] = Time.zone.now
      end

      clean_params
    end
  end
end
