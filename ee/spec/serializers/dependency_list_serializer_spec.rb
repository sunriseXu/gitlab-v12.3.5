# frozen_string_literal: true

require 'spec_helper'

describe DependencyListSerializer do
  set(:project) { create(:project, :repository, :private) }
  set(:user) { create(:user) }
  let(:ci_build) { create(:ee_ci_build, :success) }
  let(:dependencies) { [build(:dependency, :with_vulnerabilities, :with_licenses)] }

  let(:serializer) do
    described_class.new(project: project, user: user).represent(dependencies, build: ci_build)
  end

  before do
    stub_licensed_features(security_dashboard: true, license_management: true)
    project.add_developer(user)
  end

  describe "#to_json" do
    subject { serializer.to_json }

    it 'matches the schema' do
      is_expected.to match_schema('dependency_list', dir: 'ee')
    end
  end
end
