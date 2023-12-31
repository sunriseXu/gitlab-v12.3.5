# frozen_string_literal: true

require 'spec_helper'

describe CountriesController do
  describe 'GET #index' do
    it 'returns list of countries as json' do
      get :index

      expected_json = World.countries_for_select.to_json

      expect(response.status).to eq(200)
      expect(response.body).to eq(expected_json)
    end

    it 'does not include list of denied countries' do
      get :index

      # response is returned as [["Afghanistan", "AF"], ["Albania", "AL"], ..]
      resultant_countries = JSON.parse(response.body).map {|row| row[0]}

      expect(resultant_countries).not_to include(World::DENYLIST)
    end
  end
end
