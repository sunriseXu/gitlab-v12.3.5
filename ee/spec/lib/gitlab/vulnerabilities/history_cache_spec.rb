# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Vulnerabilities::HistoryCache do
  let(:group) { create(:group) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:project_cache_key) { described_class.new(group, project.id).send(:cache_key) }

  before do
    create_vulnerabilities(1, project)
  end

  describe '#fetch', :use_clean_rails_memory_store_caching do
    it 'reads from cache when records are cached' do
      history_cache = described_class.new(group, project.id)

      expect(Rails.cache.fetch(project_cache_key, raw: true)).to be_nil

      control_count = ActiveRecord::QueryRecorder.new { history_cache.fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE) }

      expect { 2.times { history_cache.fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE) } }.not_to exceed_query_limit(control_count)
    end

    it 'returns the proper format for uncached history' do
      Timecop.freeze do
        fetched_history = described_class.new(group, project.id).fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE)

        expect(fetched_history[:total]).to eq( Date.today => 1 )
        expect(fetched_history[:high]).to eq( Date.today => 1 )
      end
    end

    it 'returns the proper format for cached history' do
      Timecop.freeze do
        described_class.new(group, project.id).fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE)
        fetched_history = described_class.new(group, project.id).fetch(Gitlab::Vulnerabilities::History::HISTORY_RANGE)

        expect(fetched_history[:total]).to eq( Date.today => 1 )
        expect(fetched_history[:high]).to eq( Date.today => 1 )
      end
    end

    def create_vulnerabilities(count, project, options = {})
      report_type = options[:report_type] || :sast
      pipeline = create(:ci_pipeline, :success, project: project)
      create_list(:vulnerabilities_occurrence, count, report_type: report_type, pipelines: [pipeline], project: project)
    end
  end
end
