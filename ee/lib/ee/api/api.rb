# frozen_string_literal: true

module EE
  module API
    module API
      extend ActiveSupport::Concern

      prepended do
        use ::Gitlab::Middleware::IpRestrictor

        mount ::EE::API::Boards
        mount ::EE::API::GroupBoards

        mount ::API::ProjectApprovalRules
        mount ::API::ProjectApprovalSettings
        mount ::API::Unleash
        mount ::API::EpicIssues
        mount ::API::EpicLinks
        mount ::API::Epics
        mount ::API::ContainerRegistryEvent
        mount ::API::Geo
        mount ::API::GeoNodes
        mount ::API::IssueLinks
        mount ::API::Ldap
        mount ::API::LdapGroupLinks
        mount ::API::License
        mount ::API::ProjectMirror
        mount ::API::ProjectPushRule
        mount ::API::ConanPackages
        mount ::API::MavenPackages
        mount ::API::NpmPackages
        mount ::API::Packages
        mount ::API::PackageFiles
        mount ::API::Scim
        mount ::API::ManagedLicenses
        mount ::API::ProjectApprovals
        mount ::API::Vulnerabilities
        mount ::API::MergeRequestApprovals
        mount ::API::MergeRequestApprovalRules
        mount ::API::ProjectAliases
        mount ::API::Dependencies

        version 'v3', using: :path do
          # Although the following endpoints are kept behind V3 namespace,
          # they're not deprecated neither should be removed when V3 get
          # removed.  They're needed as a layer to integrate with Jira
          # Development Panel.
          namespace '/', requirements: ::API::V3::Github::ENDPOINT_REQUIREMENTS do
            mount ::API::V3::Github
          end
        end
      end
    end
  end
end
