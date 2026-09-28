# spec/fips/county_spec.rb
require "spec_helper"

RSpec.describe FIPS::County do
  describe ".county_file" do
    it "returns the path to the county csv of the given state" do
      expect(FIPS::County.county_file(state_code: "MI")).to include("lib/data/county/MI.csv")
    end
  end
end
