# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          UNSAFE_SEVERITIES = %w[unknown high critical].freeze

          attr_reader :type
          attr_reader :commit_sha
          attr_reader :occurrences
          attr_reader :scanners
          attr_reader :identifiers

          attr_accessor :error

          def initialize(type, commit_sha)
            @type = type
            @commit_sha = commit_sha
            @occurrences = []
            @scanners = {}
            @identifiers = {}
          end

          def errored?
            error.present?
          end

          def add_scanner(scanner)
            scanners[scanner.key] ||= scanner
          end

          def add_identifier(identifier)
            identifiers[identifier.key] ||= identifier
          end

          def add_occurrence(occurrence)
            occurrences << occurrence
          end

          def clone_as_blank
            Report.new(type, commit_sha)
          end

          def replace_with!(other)
            instance_variables.each do |ivar|
              instance_variable_set(ivar, other.public_send(ivar.to_s[1..-1])) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          def merge!(other)
            replace_with!(::Security::MergeReportsService.new(self, other).execute)
          end

          def unsafe_severity?
            occurrences.any? { |occurrence| UNSAFE_SEVERITIES.include?(occurrence.severity) }
          end
        end
      end
    end
  end
end
