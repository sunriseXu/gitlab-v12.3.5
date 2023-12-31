# frozen_string_literal: true

FactoryBot.define do
  factory :container_repository_registry, class: Geo::ContainerRepositoryRegistry do
    container_repository
    last_sync_failure nil
    last_synced_at nil
    state :pending

    trait :started do
      state :started
    end

    trait :synced do
      state :synced
      last_synced_at { 5.days.ago }
    end

    trait :sync_failed do
      state :failed
      last_synced_at { 1.day.ago }
      retry_count 2
      last_sync_failure 'Random error'
    end

    trait :sync_started do
      state :started
      last_synced_at { 1.day.ago }
      retry_count 0
    end
  end
end
