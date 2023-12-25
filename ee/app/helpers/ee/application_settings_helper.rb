# frozen_string_literal: true

module EE
  module ApplicationSettingsHelper
    extend ::Gitlab::Utils::Override

    def pseudonymizer_enabled_help_text
      _("Enable Pseudonymizer data collection")
    end

    def pseudonymizer_description_text
      _("GitLab will run a background job that will produce pseudonymized CSVs of the GitLab database that will be uploaded to your configured object storage directory.")
    end

    def pseudonymizer_disabled_description_text
      _("The pseudonymizer data collection is disabled. When enabled, GitLab will run a background job that will produce pseudonymized CSVs of the GitLab database that will be uploaded to your configured object storage directory.")
    end

    override :visible_attributes
    def visible_attributes
      super + [
        :allow_group_owners_to_manage_ldap,
        :check_namespace_plan,
        :elasticsearch_aws,
        :elasticsearch_aws_access_key,
        :elasticsearch_aws_region,
        :elasticsearch_aws_secret_access_key,
        :elasticsearch_indexing,
        :elasticsearch_replicas,
        :elasticsearch_search,
        :elasticsearch_shards,
        :elasticsearch_url,
        :elasticsearch_limit_indexing,
        :elasticsearch_namespace_ids,
        :elasticsearch_project_ids,
        :geo_status_timeout,
        :geo_node_allowed_ips,
        :help_text,
        :lock_memberships_to_ldap,
        :pseudonymizer_enabled,
        :repository_size_limit,
        :shared_runners_minutes,
        :slack_app_enabled,
        :slack_app_id,
        :slack_app_secret,
        :slack_app_verification_token
      ]
    end

    def elasticsearch_objects_options(objects)
      objects.map { |g| { id: g.id, text: g.full_name } }
    end

    def elasticsearch_namespace_ids
      ElasticsearchIndexedNamespace.target_ids.join(',')
    end

    def elasticsearch_project_ids
      ElasticsearchIndexedProject.target_ids.join(',')
    end

    def self.repository_mirror_attributes
      [
        :mirror_max_capacity,
        :mirror_max_delay,
        :mirror_capacity_threshold
      ]
    end

    def self.possible_licensed_attributes
      repository_mirror_attributes + %i[
        email_additional_text
        file_template_project_id
        default_project_deletion_protection
      ]
    end
  end
end
