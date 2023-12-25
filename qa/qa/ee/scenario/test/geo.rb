# frozen_string_literal: true

require 'net/http'
require 'json'

module QA
  module EE
    module Scenario
      module Test
        class Geo < QA::Scenario::Template
          include QA::Scenario::Bootable

          tags :geo

          attribute :geo_primary_address, '--primary-address PRIMARY'
          attribute :geo_primary_name, '--primary-name PRIMARY_NAME'
          attribute :geo_secondary_address, '--secondary-address SECONDARY'
          attribute :geo_secondary_name, '--secondary-name SECONDARY_NAME'
          attribute :geo_skip_setup?, '--without-setup'

          def perform(options, *rspec_options)
            # Alias QA::Runtime::Scenario.gitlab_address to @address since
            # some components depends on QA::Runtime::Scenario.gitlab_address.
            QA::Runtime::Scenario.define(:gitlab_address, QA::Runtime::Scenario.geo_primary_address)

            unless options[:geo_skip_setup?]
              Geo::Primary.act do
                add_license
                enable_hashed_storage
                set_replication_password
                set_primary_node
                add_secondary_node
              end

              Geo::Secondary.act do
                replicate_database
                reconfigure
                wait_for_services
                authorize
              end
            end

            Specs::Runner.perform do |specs|
              specs.tty = true
              specs.tags = self.class.focus
              specs.options = rspec_options if rspec_options.any?
            end
          end

          class Primary
            include QA::Scenario::Actable

            def initialize
              @name = QA::Runtime::Scenario.geo_primary_name
              @address = QA::Runtime::Scenario.geo_primary_address
            end

            def add_license
              puts 'Adding GitLab EE license ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                Resource::License.fabricate!(ENV['EE_LICENSE'])
              end
            end

            def enable_hashed_storage
              puts 'Enabling hashed repository storage setting ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                QA::Resource::Settings::HashedStorage.fabricate!(:enabled)
              end
            end

            def add_secondary_node
              puts 'Adding new Geo secondary node ...'

              QA::Runtime::Browser.visit(:geo_primary, QA::Page::Main::Login) do
                Resource::Geo::Node.fabricate! do |node|
                  node.name = QA::Runtime::Scenario.geo_secondary_name
                  node.address = QA::Runtime::Scenario.geo_secondary_address
                end
              end
            end

            def set_replication_password
              puts 'Setting replication password on primary node ...'

              QA::Service::Omnibus.new(@name).act do
                gitlab_ctl 'set-replication-password', input: 'echo mypass'
              end
            end

            def set_primary_node
              puts 'Making this node a primary node  ...'

              QA::Service::Omnibus.new(@name).act do
                gitlab_ctl 'set-geo-primary-node'
              end
            end
          end

          class Secondary
            include QA::Scenario::Actable

            def initialize
              @address = QA::Runtime::Scenario.geo_secondary_address
              @name = QA::Runtime::Scenario.geo_secondary_name
            end

            def replicate_database
              puts 'Starting Geo replication on secondary node ...'

              QA::Service::Omnibus.new(@name).act do
                require 'uri'

                host = URI(QA::Runtime::Scenario.geo_primary_address).host
                slot = QA::Runtime::Scenario.geo_primary_name.tr('-', '_')

                gitlab_ctl "replicate-geo-database --host=#{host} --slot-name=#{slot} " \
                           "--sslmode=disable --no-wait --force", input: 'echo mypass'
              end
            end

            def reconfigure
              # Without this step, the /var/opt/gitlab/postgresql/data/pg_hba.conf
              # that is left behind from 'gitlab_ctl "replicate-geo-database ..'
              # does not allow FDW to work.
              puts 'Reconfiguring ...'

              QA::Service::Omnibus.new(@name).act do
                gitlab_ctl 'reconfigure'
              end
            end

            def wait_for_services
              puts 'Waiting until secondary node services are ready ...'

              Time.new.tap do |start|
                while Time.new - start < 120
                  begin
                    Net::HTTP.get(URI.join(@address, '/-/readiness')).tap do |body|
                      if JSON.parse(body).all? { |_, service| service['status'] == 'ok' }
                        return puts "\nSecondary ready after #{Time.now - start} seconds." # rubocop:disable Cop/AvoidReturnFromBlocks
                      else
                        print '.'
                      end
                    end
                  rescue StandardError
                    print 'e'
                  end

                  sleep 1
                end

                raise "Secondary node did not start correctly in #{Time.now - start} seconds!"
              end
            end

            def authorize
              # Provide OAuth authorization now so that tests don't have to
              QA::Runtime::Browser.visit(:geo_secondary, QA::Page::Main::Login) do
                QA::Page::Main::Login.perform(&:sign_in_using_credentials)
                QA::Page::Main::OAuth.perform do |oauth|
                  oauth.authorize! if oauth.needs_authorization?
                end

                # Log out so that tests are in an initially unauthenticated state
                QA::Page::Main::Menu.perform(&:sign_out)
              end
            end
          end
        end
      end
    end
  end
end
