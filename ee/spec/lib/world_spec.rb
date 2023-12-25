# frozen_string_literal: true

require 'spec_helper'

describe World do
  describe '.all_countries' do
    it 'does not return countries that are in the denied list' do
      result = described_class.all_countries

      expect(result.map(&:name)).not_to include(World::DENYLIST)
    end
  end

  describe '.countries_for_select' do
    it 'returns list of country name and iso_code in alphabetical format' do
      result = described_class.countries_for_select

      expect(result.first).to eq(%w[Afghanistan AF])
    end
  end
end
