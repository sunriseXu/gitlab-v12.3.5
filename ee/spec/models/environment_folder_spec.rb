# frozen_string_literal: true

require 'spec_helper'

describe EnvironmentFolder do
  describe '.find_for_projects' do
    it 'returns an environment within a folder when the last environment does not have an environment_type' do
      project = create(:project)
      create(:environment, project: project, name: 'production/azure')
      last_environment = create(:environment, project: project, name: 'production')

      projects_with_environment_folders = described_class.find_for_projects([project])

      environment_folder = projects_with_environment_folders[project].first
      expect(environment_folder.last_environment.id).to eq(last_environment.id)
      expect(environment_folder.within_folder?).to eq(true)
    end

    it 'returns an environment outside a folder' do
      project = create(:project)
      create(:environment, project: project, name: 'production')

      projects_with_environment_folders = described_class.find_for_projects([project])

      environment_folder = projects_with_environment_folders[project].first
      expect(environment_folder.within_folder?).to eq(false)
    end

    it 'returns a project without any environments' do
      project = create(:project)

      projects_with_environment_folders = described_class.find_for_projects([project])

      expect(projects_with_environment_folders).to eq({ project => [] })
    end

    it 'returns a project without any available environments' do
      project = create(:project)
      create(:environment, project: project, state: :stopped)

      projects_with_environment_folders = described_class.find_for_projects([project])

      expect(projects_with_environment_folders).to eq({ project => [] })
    end

    it 'returns multiple projects' do
      project1 = create(:project)
      project2 = create(:project)
      create(:environment, project: project1, state: :stopped)
      environment = create(:environment, project: project2, state: :available)

      projects_with_environment_folders = described_class.find_for_projects([project1, project2])

      expect(projects_with_environment_folders[project1]).to eq([])
      expect(projects_with_environment_folders[project2].count).to eq(1)

      environment_folder = projects_with_environment_folders[project2].first

      expect(environment_folder.last_environment).to eq(environment)
    end
  end
end
