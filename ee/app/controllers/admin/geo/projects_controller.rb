# frozen_string_literal: true

class Admin::Geo::ProjectsController < Admin::Geo::ApplicationController
  before_action :check_license!
  before_action :load_registry, except: [:index]
  before_action :limited_actions_message!

  def index
    @registries = case params[:sync_status]
                  when 'never'
                    finder.never_synced_projects.page(params[:page])
                  when 'failed'
                    finder.failed_projects.page(params[:page])
                  when 'pending'
                    finder.pending_projects.page(params[:page])
                  when 'synced'
                    finder.synced_projects.page(params[:page])
                  else
                    finder.all_projects.page(params[:page])
                  end

    if params[:name]
      @registries = @registries.with_search(params[:name])
    end
  end

  def destroy
    unless @registry.project.nil?
      return redirect_back_or_admin_geo_projects(alert: s_('Geo|Could not remove tracking entry for an existing project.'))
    end

    @registry.destroy

    redirect_back_or_admin_geo_projects(notice: s_('Geo|Tracking entry for project (%{project_id}) was successfully removed.') % { project_id: @registry.project_id })
  end

  def reverify
    @registry.flag_repository_for_reverify!

    redirect_back_or_admin_geo_projects(notice: s_('Geo|%{name} is scheduled for re-verify') % { name: @registry.project.full_name })
  end

  def resync
    @registry.flag_repository_for_resync!

    redirect_back_or_admin_geo_projects(notice: s_('Geo|%{name} is scheduled for re-sync') % { name: @registry.project.full_name })
  end

  def force_redownload
    @registry.flag_repository_for_redownload!

    redirect_back_or_admin_geo_projects(notice: s_('Geo|%{name} is scheduled for forced re-download') % { name: @registry.project.full_name })
  end

  def reverify_all
    Geo::Batch::ProjectRegistrySchedulerWorker.perform_async(:reverify_repositories)

    redirect_back_or_admin_geo_projects(notice: s_('Geo|All projects are being scheduled for re-verify'))
  end

  def resync_all
    Geo::Batch::ProjectRegistrySchedulerWorker.perform_async(:resync_repositories)

    redirect_back_or_admin_geo_projects(notice: s_('Geo|All projects are being scheduled for re-sync'))
  end

  private

  def load_registry
    @registry = ::Geo::ProjectRegistry.find_by_id(params[:id])
  end

  def redirect_back_or_admin_geo_projects(params)
    redirect_back_or_default(default: admin_geo_projects_path, options: params)
  end

  def finder
    @finder ||= ::Geo::ProjectRegistryStatusFinder.new
  end
end
