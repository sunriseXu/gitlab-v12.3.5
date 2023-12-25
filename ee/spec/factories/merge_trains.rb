# frozen_string_literal: true

FactoryBot.define do
  factory :merge_train do
    target_branch 'master'
    target_project factory: :project
    merge_request
    user
    pipeline factory: :ci_pipeline
  end
end
