# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::LicenseManagement::ReportsComparer do
  let(:report_1) { build :ci_reports_license_management_report, :report_1 }
  let(:report_2) { build :ci_reports_license_management_report, :report_2 }
  let(:report_comparer) { described_class.new(report_1, report_2) }

  before do
    report_1.add_dependency('BSD', 1, 'https://opensource.org/licenses/0BSD', 'Library1')
    report_2.add_dependency('bsd', 1, 'https://opensource.org/licenses/0BSD', 'Library1')
  end

  def names_from(licenses)
    licenses.map(&:name)
  end

  describe '#new_licenses' do
    subject { report_comparer.new_licenses }

    it { expect(names_from(subject)).to contain_exactly('Apache 2.0') }
  end

  describe '#existing_licenses' do
    subject { report_comparer.existing_licenses }

    it { expect(names_from(subject)).to contain_exactly('MIT', 'BSD') }
  end

  describe '#removed_licenses' do
    subject { report_comparer.removed_licenses }

    it { expect(names_from(subject)).to contain_exactly('WTFPL') }
  end
end
