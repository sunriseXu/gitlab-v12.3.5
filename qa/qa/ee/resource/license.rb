# frozen_string_literal: true

module QA
  module EE
    module Resource
      class License < QA::Resource::Base
        def fabricate!(license)
          QA::Page::Main::Login.perform(&:sign_in_using_admin_credentials)
          QA::Page::Main::Menu.perform(&:click_admin_area)
          QA::Page::Admin::Menu.perform(&:click_license_menu_link)

          EE::Page::Admin::License.perform do |page| # rubocop:disable QA/AmbiguousPageObjectName
            page.add_new_license(license) unless page.license?
          end

          QA::Page::Main::Menu.perform(&:sign_out)
        end
      end
    end
  end
end
