# frozen_string_literal: true

module EE
  module API
    module Helpers
      module IssuesHelpers
        extend ActiveSupport::Concern

        prepended do
          params :optional_issue_params_ee do
            optional :weight, type: Integer, desc: 'The weight of the issue'
          end

          params :optional_issues_params_ee do
            optional :weight, types: [Integer, String], integer_none_any: true, desc: 'The weight of the issue'
          end
        end

        class_methods do
          extend ::Gitlab::Utils::Override

          override :update_params_at_least_one_of
          def update_params_at_least_one_of
            [*super, :weight]
          end

          override :sort_options
          def sort_options
            [*super, 'weight']
          end
        end
      end
    end
  end
end
