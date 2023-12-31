# frozen_string_literal: true
require 'spec_helper'

describe Geo::ProjectRegistryStatusFinder, :geo, :geo_tracking_db do
  include ::EE::GeoHelpers

  set(:secondary) { create(:geo_node) }

  set(:synced_registry) { create(:geo_project_registry, :synced) }
  set(:synced_and_verified_registry) { create(:geo_project_registry, :synced, :repository_verified) }
  set(:sync_pending_registry) { create(:geo_project_registry, :synced, :repository_dirty) }
  set(:sync_failed_registry) { create(:geo_project_registry, :existing_repository_sync_failed) }

  set(:verify_outdated_registry) { create(:geo_project_registry, :synced, :repository_verification_outdated) }
  set(:verify_failed_registry) { create(:geo_project_registry, :synced, :repository_verification_failed) }
  set(:verify_checksum_mismatch_registry) { create(:geo_project_registry, :synced, :repository_checksum_mismatch) }

  set(:never_synced_registry) { create(:geo_project_registry) }
  set(:never_synced_registry_with_failure) { create(:geo_project_registry, :repository_sync_failed) }

  before do
    stub_current_geo_node(secondary)
  end

  describe '#all_projects' do
    it 'returns all registries' do
      result = subject.all_projects

      expect(result).to contain_exactly(synced_registry, synced_and_verified_registry, sync_pending_registry,
                                        sync_failed_registry, verify_outdated_registry, verify_failed_registry,
                                        verify_checksum_mismatch_registry, never_synced_registry,
                                        never_synced_registry_with_failure)
    end
  end

  describe '#synced_projects' do
    it 'returns only synced registry' do
      result = subject.synced_projects

      expect(result).to contain_exactly(synced_and_verified_registry)
    end
  end

  describe '#pending_projects' do
    it 'returns only pending registry' do
      result = subject.pending_projects

      expect(result).to contain_exactly(
        synced_registry,
        sync_pending_registry,
        verify_outdated_registry
      )
    end
  end

  describe '#failed_projects' do
    it 'returns only failed registry' do
      result = subject.failed_projects

      expect(result).to contain_exactly(
        sync_failed_registry,
        never_synced_registry_with_failure,
        verify_failed_registry,
        verify_checksum_mismatch_registry
      )
    end
  end

  describe '#never_synced_projects' do
    it 'returns only never fully synced registries' do
      result = subject.never_synced_projects

      expect(result).to contain_exactly(
        never_synced_registry,
        never_synced_registry_with_failure
      )
    end
  end
end
