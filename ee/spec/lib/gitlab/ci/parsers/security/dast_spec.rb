# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Dast do
  let(:parser) { described_class.new }

  describe '#parse!' do
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:artifact) { create(:ee_ci_job_artifact, :dast) }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(artifact.file_type, pipeline.sha) }

    before do
      artifact.each_blob do |blob|
        parser.parse!(blob, report)
      end
    end

    it 'parses all identifiers and occurrences' do
      expect(report.occurrences.length).to eq(2)
      expect(report.identifiers.length).to eq(3)
      expect(report.scanners.length).to eq(1)
    end

    it 'generates expected location' do
      location = report.occurrences.first.location

      expect(location).to be_a(::Gitlab::Ci::Reports::Security::Locations::Dast)
      expect(location).to have_attributes(
        hostname: 'http://bikebilly-spring-auto-devops-review-feature-br-3y2gpb.35.192.176.43.xip.io',
        method_name: 'GET',
        param: 'X-Content-Type-Options',
        path: ''
      )
    end

    describe 'occurrence properties' do
      using RSpec::Parameterized::TableSyntax

      where(:attribute, :value) do
        :report_type | 'dast'
        :severity | 'low'
        :confidence | 'medium'
      end

      with_them do
        it 'saves properly occurrence' do
          occurrence = report.occurrences.last

          expect(occurrence.public_send(attribute)).to eq(value)
        end
      end
    end
  end
end
