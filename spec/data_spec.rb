# frozen_string_literal: true

require "csv"

RSpec.describe FIPS do
  describe "source data" do
    it "matches county CSV row counts to county lookup counts for each state" do
      FIPS::State.all.each do |state|
        state_abbr = state[:abbr]
        county_file_path = FIPS::County.file_path(state_abbr)
        county_file_length = CSV.foreach(county_file_path).count
        lookup_count = FIPS::County.all(state: state_abbr).count

        expect(lookup_count).to eq(county_file_length), "county count differs for #{state_abbr}"
      end
    end

    it "matches subdivision CSV row counts to subdivision lookup counts for each state" do
      FIPS::State.all.each do |state|
        state_abbr = state[:abbr]
        subdivision_file_path = FIPS::Subdivision.file_path(state_abbr)
        subdivision_file_length = CSV.foreach(subdivision_file_path).count
        lookup_count = FIPS::Subdivision.all(state: state_abbr).count

        expect(lookup_count).to eq(subdivision_file_length), "subdivision count differs for #{state_abbr}"
      end
    end
  end
end
