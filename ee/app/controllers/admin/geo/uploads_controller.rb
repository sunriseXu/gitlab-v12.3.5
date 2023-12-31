# frozen_string_literal: true

class Admin::Geo::UploadsController < Admin::Geo::ApplicationController
  before_action :check_license!
  before_action :registries, only: [:index]

  def index
  end

  def destroy
    if registry.upload
      return redirect_admin_geo_uploads(alert: s_('Geo|Could not remove tracking entry for an existing upload.'))
    end

    registry.destroy

    redirect_admin_geo_uploads(notice: s_('Geo|Tracking entry for upload (%{type}/%{id}) was successfully removed.') % { type: registry.file_type, id: registry.file_id })
  end

  private

  def registries
    @registries ||=
      ::Geo::UploadRegistry
        .with_status(params[:sync_status])
        .with_search(params[:name])
        .fresh
        .page(params[:page])
  end

  def registry
    @registry ||= ::Geo::UploadRegistry.find_by_id(params[:id])
  end

  def redirect_admin_geo_uploads(options)
    redirect_back_or_default(default: admin_geo_uploads_path, options: options)
  end
end
