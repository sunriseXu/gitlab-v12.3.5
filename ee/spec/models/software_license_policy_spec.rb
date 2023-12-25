# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicensePolicy do
  subject { build(:software_license_policy) }

  describe 'validations' do
    it { is_expected.to include_module(Presentable) }
    it { is_expected.to validate_presence_of(:software_license) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:approval_status) }
    it { is_expected.to validate_uniqueness_of(:software_license).scoped_to(:project_id).with_message(/has already been taken/) }
  end

  describe ".with_license_by_name" do
    subject { described_class }
    let!(:mit_policy) { create(:software_license_policy, software_license: mit) }
    let!(:mit) { create(:software_license, :mit) }
    let!(:apache_policy) { create(:software_license_policy, software_license: apache) }
    let!(:apache) { create(:software_license, :apache_2_0) }

    it 'finds a license by an exact match' do
      expect(subject.with_license_by_name(mit.name)).to match_array([mit_policy])
    end

    it 'finds a license by a case insensitive match' do
      expect(subject.with_license_by_name('mIt')).to match_array([mit_policy])
    end

    it 'finds multiple licenses' do
      expect(subject.with_license_by_name([mit.name, apache.name])).to match_array([mit_policy, apache_policy])
    end
  end

  describe "#name" do
    specify { expect(subject.name).to eql(subject.software_license.name) }
  end
end
