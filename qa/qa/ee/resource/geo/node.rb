# frozen_string_literal: true

module QA
  module EE
    module Resource
      module Geo
        class Node < QA::Resource::Base
          attr_accessor :name
          attr_accessor :address

          def fabricate!
            QA::Page::Main::Login.perform(&:sign_in_using_credentials)
            QA::Page::Main::Menu.perform(&:click_admin_area)
            QA::Page::Admin::Menu.perform(&:click_geo_menu_link)
            EE::Page::Admin::Geo::Nodes::Show.perform(&:new_node!)

            EE::Page::Admin::Geo::Nodes::New.perform do |page| # rubocop:disable QA/AmbiguousPageObjectName
              raise ArgumentError if @name.nil? || @address.nil?

              page.set_node_name(@name)
              page.set_node_address(@address)
              page.add_node!
            end

            QA::Page::Main::Menu.perform(&:sign_out)
          end
        end
      end
    end
  end
end
