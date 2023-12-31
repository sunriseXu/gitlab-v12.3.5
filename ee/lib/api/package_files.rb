# frozen_string_literal: true

module API
  class PackageFiles < Grape::API
    include PaginationParams

    before do
      require_packages_enabled!
      authorize_packages_feature!
      authorize_read_package!
    end

    helpers ::API::Helpers::PackagesHelpers

    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :package_id, type: Integer, desc: 'The ID of a package'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get all package files' do
        detail 'This feature was introduced in GitLab 11.8'
        success EE::API::Entities::PackageFile
      end
      params do
        use :pagination
      end
      get ':id/packages/:package_id/package_files' do
        package = ::Packages::PackageFinder
          .new(user_project, params[:package_id]).execute

        present paginate(package.package_files), with: EE::API::Entities::PackageFile
      end
    end
  end
end
