# frozen_string_literal: true

class Admin::Geo::ApplicationController < Admin::ApplicationController
  helper ::EE::GeoHelper

  protected

  def check_license!
    unless Gitlab::Geo.license_allows?
      flash[:alert] = _('You need a different license to use Geo replication.')
      redirect_to admin_license_path
    end
  end
end
