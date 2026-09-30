# frozen_string_literal: true

require "pathname"

RSpec.describe FIPS do
  it "has a version number" do
    expect(FIPS::VERSION).not_to be nil
  end
end
