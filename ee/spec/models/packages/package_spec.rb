# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Package, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:package_files).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe '#name' do
      it { is_expected.to allow_value("my/domain/com/my-app").for(:name) }
      it { is_expected.to allow_value("my.app-11.07.2018").for(:name) }
      it { is_expected.not_to allow_value("my(dom$$$ain)com.my-app").for(:name) }
    end

    describe '#package_already_taken' do
      context 'npm package' do
        let!(:package) { create(:npm_package) }

        it 'will not allow a package of the same name' do
          new_package = build(:npm_package, name: package.name)

          expect(new_package).not_to be_valid
        end
      end

      context 'maven package' do
        let!(:package) { create(:maven_package) }

        it 'will allow a package of the same name' do
          new_package = build(:maven_package, name: package.name)

          expect(new_package).to be_valid
        end
      end
    end
  end

  describe '#destroy' do
    let(:package) { create(:npm_package) }
    let(:package_file) { package.package_files.first }
    let(:project_statistics) { ProjectStatistics.for_project_ids(package.project.id).first }

    it 'affects project statistics' do
      expect { package.destroy! }
        .to change { project_statistics.reload.packages_size }
              .from(package_file.size).to(0)
    end
  end

  describe '.by_name_and_file_name' do
    let!(:package) { create(:npm_package) }
    let!(:package_file) { package.package_files.first }

    subject { described_class }

    it 'finds a package with correct arguiments' do
      expect(subject.by_name_and_file_name(package.name, package_file.file_name)).to eq(package)
    end

    it 'will raise error if not found' do
      expect { subject.by_name_and_file_name('foo', 'foo-5.5.5.tgz') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'version scopes' do
    let!(:package1) { create(:npm_package, version: '1.0.0') }
    let!(:package2) { create(:npm_package, version: '1.0.1') }
    let!(:package3) { create(:npm_package, version: '1.0.1') }

    describe '.last_of_each_version' do
      subject { described_class.last_of_each_version }

      it 'includes only latest package per version' do
        is_expected.to include(package1, package3)
        is_expected.not_to include(package2)
      end
    end

    describe '.has_version' do
      let!(:package4) { create(:npm_package, version: nil) }

      subject { described_class.has_version }

      it 'includes only packages with version attribute' do
        is_expected.to match_array([package1, package2, package3])
      end
    end

    describe '.with_version' do
      subject { described_class.with_version('1.0.1') }

      it 'includes only packages with specified version' do
        is_expected.to match_array([package2, package3])
      end
    end
  end
end
