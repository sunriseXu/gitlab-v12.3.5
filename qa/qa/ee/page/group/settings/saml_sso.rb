# frozen_string_literal: true

module QA
  module EE
    module Page
      module Group
        module Settings
          class SamlSSO < ::QA::Page::Base
            view 'ee/app/views/groups/saml_providers/_form.html.haml' do
              element :identity_provider_sso_field
              element :certificate_fingerprint_field
              element :enforced_sso_toggle_button
              element :save_changes_button
            end

            view 'ee/app/views/groups/saml_providers/_test_button.html.haml' do
              element :saml_settings_test_button
            end

            view 'ee/app/views/groups/saml_providers/_info.html.haml' do
              element :user_login_url_link
            end

            def set_id_provider_sso_url(url)
              fill_element :identity_provider_sso_field, url
            end

            def set_cert_fingerprint(fingerprint)
              fill_element :certificate_fingerprint_field, fingerprint
            end

            def enforce_sso
              click_element :enforced_sso_toggle_button unless find_element(:enforced_sso_toggle_button)[:class].include?('is-checked')
            end

            def click_save_changes
              click_element :save_changes_button
            end

            def click_test_button
              click_element :saml_settings_test_button
            end

            def click_user_login_url_link
              click_element :user_login_url_link
            end
          end
        end
      end
    end
  end
end
