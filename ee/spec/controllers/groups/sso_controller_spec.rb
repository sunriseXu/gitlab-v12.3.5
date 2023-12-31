# frozen_string_literal: true

require 'spec_helper'

describe Groups::SsoController do
  let(:user) { create(:user) }
  let(:group) { create(:group, :private, name: 'our-group', saml_discovery_token: 'test-token') }

  before do
    stub_licensed_features(group_saml: true)
    allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))
    sign_in(user)
  end

  context 'SAML configured' do
    let!(:saml_provider) { create(:saml_provider, group: group) }

    it 'has status 200' do
      get :saml, params: { group_id: group }

      expect(response).to have_gitlab_http_status(200)
    end

    it 'malicious redirect parameter falls back to group_path' do
      get :saml, params: { group_id: group, redirect: '///malicious-url' }

      expect(response).to have_gitlab_http_status(200)
      expect(assigns[:redirect_path]).to eq(group_path(group))
    end

    it 'passes group name to the view' do
      get :saml, params: { group_id: group }

      expect(assigns[:group_name]).to eq 'our-group'
    end

    it 'allows account unlinking' do
      create(:group_saml_identity, saml_provider: saml_provider, user: user)

      expect do
        delete :unlink, params: { group_id: group }
      end.to change(Identity, :count).by(-1)
    end

    context 'when SAML is disabled for the group' do
      before do
        saml_provider.update!(enabled: false)
      end

      it 'renders 404' do
        get :saml, params: { group_id: group }

        expect(response).to have_gitlab_http_status(404)
      end

      it 'still allows account unlinking' do
        create(:group_saml_identity, saml_provider: saml_provider, user: user)

        expect do
          delete :unlink, params: { group_id: group }
        end.to change(Identity, :count).by(-1)
      end
    end

    context 'when user is not signed in' do
      it 'acts as route not found' do
        sign_out(user)

        get :saml, params: { group_id: group }

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when group has moved' do
      let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

      it 'redirects to new location' do
        get :saml, params: { group_id: redirect_route.path }

        expect(response).to redirect_to(sso_group_saml_providers_path(group))
      end
    end
  end

  context 'saml_provider is unconfigured for the group' do
    context 'when user cannot configure Group SAML' do
      it 'renders 404' do
        get :saml, params: { group_id: group }

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user can admin group_saml' do
      before do
        group.add_owner(user)
      end

      it 'redirects to the Group SAML config page' do
        get :saml, params: { group_id: group }

        expect(response).to redirect_to(group_saml_providers_path)
      end

      it 'sets a flash message explaining that setup is required' do
        get :saml, params: { group_id: group }

        expect(flash[:notice]).to match /not been configured/
      end
    end
  end

  context 'group does not exist' do
    it 'renders 404' do
      get :saml, params: { group_id: 'not-a-group' }

      expect(response).to have_gitlab_http_status(404)
    end

    context 'when user is not signed in' do
      it 'acts as route not found' do
        sign_out(user)

        get :saml, params: { group_id: 'not-a-group' }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET sign_up_form' do
    subject do
      get :sign_up_form,
          params: { group_id: group },
          session: { "oauth_data" => oauth_data, "oauth_group_id" => oauth_group_id }
    end

    let(:oauth_data) { nil }
    let(:oauth_group_id) { group.id }

    context 'with SAML configured' do
      let!(:saml_provider) { create(:saml_provider, :enforced_group_managed_accounts, group: group) }

      context 'and group managed accounts enforced' do
        context 'and oauth data available' do
          let(:oauth_data) { { "info" => { name: 'Test', email: 'testuser@email.com' } } }

          it 'has status 200' do
            expect(subject).to have_gitlab_http_status(200)
          end

          it 'suggests first available username automatically' do
            create(:user, username: 'testuser')

            subject

            expect(controller.helpers.resource.username).to eq 'testuser1'
          end

          context 'and belongs to different group' do
            let(:oauth_group_id) { group.id + 1 }

            it 'renders 404' do
              expect(subject).to have_gitlab_http_status(404)
            end
          end
        end

        it 'renders 404' do
          expect(subject).to have_gitlab_http_status(404)
        end
      end

      context 'and group managed accounts enforcing is disabled' do
        before do
          saml_provider.update(enforced_group_managed_accounts: false)
        end

        it 'renders 404' do
          expect(subject).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'POST sign_up' do
    subject do
      post :sign_up,
           params: { group_id: group, new_user: new_user_data },
           session: { "oauth_data" => oauth_data, "oauth_group_id" => group.id }
    end

    let(:new_user_data) { { username: "myusername" } }
    let(:oauth_data) { { "info" => { name: 'Test', email: 'testuser@email.com' } } }

    let!(:saml_provider) { create(:saml_provider, :enforced_group_managed_accounts, group: group) }

    let(:sign_up_service_spy) { spy('GroupSaml::SignUpService') }

    before do
      allow(GroupSaml::SignUpService)
        .to receive(:new).with(kind_of(User), group, anything).and_return(sign_up_service_spy)
    end

    it 'calls for GroupSaml::SignUpService' do
      subject

      expect(sign_up_service_spy).to have_received(:execute)
    end

    context 'when service fails' do
      before do
        allow(sign_up_service_spy).to receive(:execute).and_return(false)
      end

      it 'renders the form' do
        expect(subject).to render_template :sign_up_form
      end
    end

    context 'when service succeeds' do
      before do
        allow(sign_up_service_spy).to receive(:execute).and_return(true)
      end

      it 'redirects to sign in' do
        subject

        expect(flash[:notice]).to eq "Sign up was successful! Please confirm your email to sign in."
        expect(response).to redirect_to sso_group_saml_providers_url(group, token: group.saml_discovery_token)
      end

      context 'when user is already signed in' do
        let(:user) { create :user }

        before do
          sign_in user
        end

        it 'signs user out' do
          subject

          expect(request.env['warden']).not_to be_authenticated
        end
      end
    end
  end
end
