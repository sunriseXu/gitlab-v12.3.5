# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        module Formatters
          class DependencyList
            def initialize(project, sha)
              @commit_path = ::Gitlab::Routing.url_helpers.project_blob_path(project, sha)
            end

            def format(dependency, package_manager, file_path, vulnerabilities = [])
              {
                name:     dependency['package']['name'],
                packager: packager(package_manager),
                package_manager: package_manager,
                location: {
                  blob_path: blob_path(file_path),
                  path:      file_path
                },
                version:  dependency['version'],
                vulnerabilities: collect_vulnerabilities(vulnerabilities, dependency, file_path),
                licenses: []
              }
            end

            private

            attr_reader :commit_path

            def blob_path(file_path)
              "#{commit_path}/#{file_path}"
            end

            # Dependency List report is generated by dependency_scanning job.
            # This is how the location is generated there
            # https://gitlab.com/gitlab-org/security-products/analyzers/common/blob/a0a5074c49f34332aa3948cd9d6dc2c054cdf3a7/issue/issue.go#L169
            def location(dependency, file_path)
              {
                'file' => file_path,
                'dependency' => {
                  'package' => {
                    'name' => dependency['package']['name']
                  },
                  'version' => dependency['version']
                }
              }
            end

            def packager(package_manager)
              case package_manager
              when 'bundler'
                'Ruby (Bundler)'
              when 'yarn'
                'JavaScript (Yarn)'
              when 'npm'
                'JavaScript (npm)'
              when 'pip'
                'Python (pip)'
              when 'maven'
                'Java (Maven)'
              when 'composer'
                'PHP (Composer)'
              else
                package_manager
              end
            end

            def collect_vulnerabilities(vulnerabilities, dependency, file_path)
              dependency_location = location(dependency, file_path)

              vulnerabilities
                .select { |vulnerability| vulnerability['location'] == dependency_location }
                .map { |vulnerability| formatted_vulnerability(vulnerability) }
            end

            def formatted_vulnerability(vulnerability)
              {
                name: vulnerability['message'],
                severity: vulnerability['severity'].downcase
              }
            end
          end
        end
      end
    end
  end
end
