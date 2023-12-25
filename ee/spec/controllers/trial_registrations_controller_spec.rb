# frozen_string_literal: true

require 'spec_helper'

describe TrialRegistrationsController do
  describe '#create' do
    before do
      stub_feature_flags(invisible_captcha: false)
      stub_application_setting(send_user_confirmation_email: true)
    end

    let(:user_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email: 'johnd2019@local.dev',
        username: 'johnd',
        password: 'abcd1234'
      }
    end

    context 'when invalid - instance is not GL.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(false)
      end

      it 'returns 404 not found' do
        post :create, params: { user: user_params }

        expect(response.status).to eq(404)
      end
    end

    context 'when feature is turned off' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_feature_flags(improved_trial_signup: false)
      end

      it 'returns not found' do
        post :create, params: { user: user_params }

        expect(response.status).to eq(404)
      end
    end

    context 'when valid' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'marks the account as confirmed' do
        post :create, params: { user: user_params }

        expect(User.last).to be_confirmed
      end

      context 'derivation of name' do
        it 'sets name from first and last name' do
          post :create, params: { user: user_params }

          expect(User.last.name).to eq("#{user_params[:first_name]} #{user_params[:last_name]}")
        end
      end

      context 'system hook' do
        it 'triggers user_create event on trial sign up' do
          expect_any_instance_of(SystemHooksService).to receive(:execute_hooks_for).with(an_instance_of(User), :create)

          post :create, params: { user: user_params }
        end

        it 'does not trigger user_create event when data is invalid' do
          user_params[:email] = ''

          expect_any_instance_of(SystemHooksService).not_to receive(:execute_hooks_for).with(an_instance_of(User), :create)

          post :create, params: { user: user_params }
        end
      end
    end
  end
end
