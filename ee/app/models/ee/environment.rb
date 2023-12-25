# frozen_string_literal: true

module EE
  module Environment
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    prepended do
      has_many :prometheus_alerts, inverse_of: :environment
      has_one :last_deployable, through: :last_deployment, source: 'deployable', source_type: 'CommitStatus'
      has_one :last_pipeline, through: :last_deployable, source: 'pipeline'

      # Returns environments where its latest deployment is to a cluster
      scope :deployed_to_cluster, -> (cluster) do
        environments = model.arel_table
        deployments = Deployment.arel_table
        later_deployments = Deployment.arel_table.alias('latest_deployments')
        join_conditions = later_deployments[:environment_id]
          .eq(deployments[:environment_id])
          .and(deployments[:id].lt(later_deployments[:id]))

        join = deployments
          .join(later_deployments, Arel::Nodes::OuterJoin)
          .on(join_conditions)

        model
          .joins(:deployments)
          .joins(join.join_sources)
          .where(later_deployments[:id].eq(nil))
          .where(deployments[:cluster_id].eq(cluster.id))
          .where(deployments[:project_id].eq(environments[:project_id]))
      end

      scope :preload_for_cluster_environment_entity, -> do
        preload(
          last_deployment: [:deployable],
          project: [:route, { namespace: :route }]
        )
      end
    end

    def reactive_cache_updated
      super

      ::Gitlab::EtagCaching::Store.new.tap do |store|
        store.touch(
          ::Gitlab::Routing.url_helpers.project_environments_path(project, format: :json))

        store.touch(cluster_environments_etag_key) if cluster_environments_etag_key
      end
    end

    def cluster_environments_etag_key
      strong_memoize(:cluster_environments_key) do
        cluster = last_deployment&.cluster

        if cluster&.group_type?
          ::Gitlab::Routing.url_helpers.environments_group_cluster_path(cluster.group, cluster)
        end
      end
    end

    def pod_names
      return [] unless rollout_status

      rollout_status.instances.map do |instance|
        instance[:pod_name]
      end
    end

    def clear_prometheus_reactive_cache!(query_name)
      cluster_prometheus_adapter&.clear_prometheus_reactive_cache!(query_name, self)
    end

    def cluster_prometheus_adapter
      @cluster_prometheus_adapter ||= Prometheus::AdapterService.new(project, deployment_platform).cluster_prometheus_adapter
    end

    def protected?
      project.protected_environment_by_name(name).present?
    end

    def protected_deployable_by_user?(user)
      project.protected_environment_accessible_to?(name, user)
    end

    def rollout_status
      return unless has_terminals?

      result = with_reactive_cache do |data|
        deployment_platform.rollout_status(self, data)
      end

      result || ::Gitlab::Kubernetes::RolloutStatus.loading
    end
  end
end
