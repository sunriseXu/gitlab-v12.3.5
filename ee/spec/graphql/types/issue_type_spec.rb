# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Issue'] do
  it { expect(described_class).to have_graphql_field(:weight) }

  it { expect(described_class).to have_graphql_field(:designs) }
end
