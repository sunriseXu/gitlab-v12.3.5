# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateAuthorizedKeysFileSince
      include Gitlab::ShellAdapter

      class Key < ActiveRecord::Base
        self.table_name = 'keys'

        def shell_id
          "key-#{id}"
        end
      end

      delegate :remove_keys_not_found_in_db, to: :gitlab_shell

      def perform(cutoff_datetime)
        add_keys_since(cutoff_datetime)

        remove_keys_not_found_in_db
      end

      def add_keys_since(cutoff_datetime)
        start_key = Key.select(:id).where("created_at >= ?", cutoff_datetime).order('id ASC').take
        if start_key
          batch_add_keys_in_db_starting_from(start_key.id)
        end
      end

      # Not added to Gitlab::Shell because I don't expect this to be used again
      def batch_add_keys_in_db_starting_from(start_id)
        Rails.logger.info("Adding all keys starting from ID: #{start_id}") # rubocop:disable Gitlab/RailsLogger

        ::Key.find_in_batches(start: start_id, batch_size: 1000) do |keys|
          gitlab_shell.batch_add_keys(keys)
        end
      end
    end
  end
end
