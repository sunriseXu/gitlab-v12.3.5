# frozen_string_literal: true

require 'net/ldap/dn'

module EE
  module Gitlab
    module Auth
      module LDAP
        module Sync
          class Proxy
            attr_reader :provider, :adapter

            # Open a connection and run all queries through it.
            # It's more efficient than the default of opening/closing per LDAP query.
            def self.open(provider, &block)
              ::Gitlab::Auth::LDAP::Adapter.open(provider) do |adapter|
                block.call(self.new(provider, adapter))
              end
            end

            def initialize(provider, adapter)
              @adapter = adapter
              @provider = provider
            end

            # Cache LDAP group member DNs so we don't query LDAP groups more than once.
            def dns_for_group_cn(group_cn)
              @dns_for_group_cn ||= Hash.new { |h, k| h[k] = ldap_group_member_dns(k) }
              @dns_for_group_cn[group_cn]
            end

            # Cache user DN so we don't generate excess queries to map UID to DN
            def dn_for_uid(uid)
              @dn_for_uid ||= Hash.new { |h, k| h[k] = member_uid_to_dn(k) }
              @dn_for_uid[uid]
            end

            def dns_for_filter(filter)
              @dns_for_filter ||= Hash.new { |h, k| h[k] = dn_filter_search(k) }
              @dns_for_filter[filter.downcase]
            end

            private

            def ldap_group_member_dns(ldap_group_cn)
              ldap_group = LDAP::Group.find_by_cn(ldap_group_cn, adapter)
              unless ldap_group.present?
                logger.warn { "Cannot find LDAP group with CN '#{ldap_group_cn}'. Skipping" }
                return []
              end

              member_dns = ldap_group.member_dns
              if member_dns.empty?
                # Group must be empty
                return [] unless ldap_group.memberuid?

                members = ldap_group.member_uids
                member_dns = members.map { |uid| dn_for_uid(uid) }
              end

              # Various lookups in this method could return `nil` values.
              # Compact the array to remove those entries
              member_dns.compact!

              ensure_full_dns!(member_dns)

              logger.debug { "Members in '#{ldap_group.name}' LDAP group: #{member_dns}" }

              # Various lookups in this method could return `nil` values.
              # Compact the array to remove those entries
              member_dns
            end

            # At least one customer reported that their LDAP `member` values contain
            # only `uid=username` and not the full DN. This method allows us to
            # account for that. See gitlab-ee#442
            def ensure_full_dns!(dns)
              dns.map! do |dn|
                begin
                  dn_obj = ::Gitlab::Auth::LDAP::DN.new(dn)
                  parsed_dn = dn_obj.to_a
                rescue ::Gitlab::Auth::LDAP::DN::FormatError => e
                  logger.error { "Found malformed DN: '#{dn}'. Skipping. Error: \"#{e.message}\"" }
                  next
                end

                final_dn =
                  # If there is more than one key/value set we must have a full DN,
                  # or at least the probability is higher.
                  if parsed_dn.count > 2
                    dn_obj.to_normalized_s
                  elsif parsed_dn.count == 0
                    logger.warn { "Found null DN. Skipping." }
                    nil
                  elsif parsed_dn[0] == 'uid'
                    dn_for_uid(parsed_dn[1])
                  else
                    logger.warn { "Found potentially malformed/incomplete DN: '#{dn}'" }
                    dn
                  end

                clean_encoding(final_dn)
              end

              # Remove `nil` values generated by the rescue above.
              dns.compact!
            end

            # net-ldap only returns ASCII-8BIT and does not support UTF-8 out-of-the-box:
            # https://github.com/ruby-ldap/ruby-net-ldap/issues/4
            def clean_encoding(dn)
              return dn unless dn.present?

              dn.force_encoding('UTF-8')
            rescue
              dn
            end

            # rubocop: disable CodeReuse/ActiveRecord
            def member_uid_to_dn(uid)
              identity = ::Identity.with_secondary_extern_uid(provider, uid).take

              if identity.present?
                # Use the DN on record in GitLab when it's available
                identity.extern_uid
              else
                ldap_user = ::Gitlab::Auth::LDAP::Person.find_by_uid(uid, adapter)

                # Can't find a matching user
                return unless ldap_user.present?

                # Update user identity so we don't have to go through this again
                update_identity(ldap_user.dn, uid)

                ldap_user.dn
              end
            end
            # rubocop: enable CodeReuse/ActiveRecord

            # rubocop: disable CodeReuse/ActiveRecord
            def update_identity(dn, uid)
              identity = ::Identity.with_extern_uid(provider, dn).take

              # User may not exist in GitLab yet. Skip.
              return unless identity.present?

              identity.secondary_extern_uid = uid
              identity.save
            end
            # rubocop: enable CodeReuse/ActiveRecord

            def dn_filter_search(filter)
              logger.debug { "Running filter \"#{filter}\" against #{provider}" }

              dns = adapter.filter_search(filter).map(&:dn)

              ensure_full_dns!(dns)

              logger.debug { "Found #{dns.count} matching users for filter #{filter}" }

              dns
            end

            def logger
              Rails.logger # rubocop:disable Gitlab/RailsLogger
            end
          end
        end
      end
    end
  end
end
