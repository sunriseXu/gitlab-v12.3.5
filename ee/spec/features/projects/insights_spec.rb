# frozen_string_literal: true

require 'spec_helper'

describe 'Project Insights' do
  it_behaves_like 'Insights page' do
    set(:entity) { create(:project) }
    let(:route) { url_for([entity.namespace, entity, :insights]) }
  end
end
