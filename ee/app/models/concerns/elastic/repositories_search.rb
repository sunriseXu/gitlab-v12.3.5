# frozen_string_literal: true

module Elastic
  module RepositoriesSearch
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Git::Repository

      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')

      def repository_id
        project.id
      end

      def es_type
        'blob'
      end

      delegate :id, to: :project, prefix: true

      def client_for_indexing
        self.__elasticsearch__.client
      end

      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20)
        response = project.repository.search(query, type: :commit, page: page, per: per_page)[:commits][:results]

        commits = response.map do |result|
          commit result["_source"]["commit"]["sha"]
        end.compact

        # Before "map" we had a paginated array so we need to recover it
        offset = per_page * ((page || 1) - 1)
        Kaminari.paginate_array(commits, total_count: response.total_count, limit: per_page, offset: offset)
      end
    end

    class_methods do
      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20, options: {})
        response = Repository.search(
          query,
          type: :commit,
          page: page,
          per: per_page,
          options: options
        )[:commits][:results]

        response_count = response.total_count

        # Avoid one SELECT per result by loading all projects into a hash
        project_ids = response.map {|result| result["_source"]["commit"]["rid"] }.uniq
        projects = Project.includes(:route).where(id: project_ids).index_by(&:id)

        commits = response.map do |result|
          project_id = result["_source"]["commit"]["rid"].to_i
          project = projects[project_id]

          if project.nil? || project.pending_delete?
            response_count -= 1
            next
          end

          raw_commit = Gitlab::Git::Commit.new(
            project.repository.raw,
            prepare_commit(result['_source']['commit']),
            lazy_load_parents: true
          )
          Commit.new(raw_commit, project)
        end

        # Remove results for deleted projects
        commits.compact!

        # Before "map" we had a paginated array so we need to recover it
        offset = per_page * ((page || 1) - 1)
        Kaminari.paginate_array(commits, total_count: response_count, limit: per_page, offset: offset)
      end

      def prepare_commit(raw_commit_hash)
        {
          id: raw_commit_hash['sha'],
          message: raw_commit_hash['message'],
          parent_ids: nil,
          author_name: raw_commit_hash['author']['name'],
          author_email: raw_commit_hash['author']['email'],
          authored_date: Time.parse(raw_commit_hash['author']['time']).utc,
          committer_name: raw_commit_hash['committer']['name'],
          committer_email: raw_commit_hash['committer']['email'],
          committed_date: Time.parse(raw_commit_hash['committer']['time']).utc
        }
      end
    end
  end
end
