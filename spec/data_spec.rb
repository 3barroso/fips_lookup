# frozen_string_literal: true

require "pathname"
require "csv"

RSpec.describe FIPS do
  describe "source data" do
    let(:source_data_path) { Pathname.new(__dir__).join("../../source_data").expand_path }

    it "matches county CSV row counts to county lookup counts for each state" do
      FIPS::State.all.each do |state|
        state_abbr = state[:abbr]
        source_path = source_data_path.join("county", "#{state_abbr}.csv")
        source_count = CSV.foreach(source_path).count
        lookup_count = FIPS::County.all(state: state_abbr).count

        expect(lookup_count).to eq(source_count), "county count differs for #{state_abbr}"
      end
    end

    it "matches subdivision CSV row counts to subdivision lookup counts for each state" do
      FIPS::State.all.each do |state|
        state_abbr = state[:abbr]
        source_path = source_data_path.join("subdivision", "#{state_abbr}.csv")
        source_count = CSV.foreach(source_path).count
        lookup_count = FIPS::Subdivision.all(state: state_abbr).count

        expect(lookup_count).to eq(source_count), "subdivision count differs for #{state_abbr}"
      end
    end
  end
end
