# frozen_string_literal: true
require 'pathname'

RSpec.describe FipsLookup do
  it "has a version number" do
    expect(FipsLookup::VERSION).not_to be nil
  end

  describe ".county" do
    context "with valid state and county params" do
      it "returns the corresponding county row hash object" do
        expect(FipsLookup.county(state: "Al", county_name: "Autauga County")).to eq({:state_code=>"AL", :fips=>"01001", :name=>"Autauga County", :class_code=>"H1"})
      end
    end

    context "with an invalid county param" do
      context "and return_nil parameter is not used" do
        it "returns an error" do
          expect{FipsLookup.county(state: "Al", county_name:"Autauga")}.to raise_error(StandardError, "No county found matching: Autauga")
        end
      end
      context "and return_nil parameter is used" do
        it "returns an empty hash object" do
          expect(FipsLookup.county(state: "Alabama", county_name: "Autauga", return_nil: true)).to eq({})
        end
      end
    end

    context "with an invalid state param" do
      context "and return_nil parameter is not used" do
        it "returns an error" do
          expect{FipsLookup.county(state: "ZZ", county_name: "County")}.to raise_error(StandardError, "No state found matching: ZZ")
        end
      end
      context "and return_nil parameter is used" do
        it "returns nil" do
          expect(FipsLookup.county(state: "ZZ", county_name: "County", return_nil: true)).to eq({})
        end
      end
    end
  end

  describe ".county" do
    it "populates a memoized hash attribute accessor with state code and county parameter as lookups" do
      expect(FipsLookup.county(state: "AL", county_name: "Autauga County")[:fips]).to eq("01001")

      lookup = ["AL".upcase, "Autauga County".upcase]
      expect(FipsLookup.county_fips[lookup][:fips]).to eq("01001")
    end

  end

  describe "STATE_CODES" do
    it "is a hash with the same number of key value pairs as rows in the state.csv file" do
      state_file_path = Pathname.getwd + "lib/data/state.csv"
      expect(FipsLookup::STATE_CODES.length - 1).to eq(`wc -l #{state_file_path}`.to_i)
    end
  end

  describe ".fips_county" do
    it "takes in a 5 digit code and finds the corresponding state county name" do
      expect(FipsLookup.fips_county(fips: "01001")).to eq(["Autauga County", "AL"])
    end

    context "when the input is not valid" do
      it "returns an error" do
        expect{FipsLookup.fips_county(fips: 12345)}.to raise_error(StandardError, "FIPS input must be 5 digit string")
        expect{FipsLookup.fips_county(fips: "123")}.to raise_error(StandardError, "FIPS input must be 5 digit string")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county(fips: 12345, return_nil: true)).to be nil
        expect(FipsLookup.fips_county(fips: "123", return_nil: true)).to be nil
      end
    end

    context "when the input is valid but state code cannot be found" do
      it "returns an error" do
        expect{FipsLookup.fips_county(fips: "03123")}.to raise_error(StandardError, "No state found matching: 03")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county(fips: "03123", return_nil: true)).to be nil
      end
    end

    context "when the input is valid but county can not be found" do
      it "returns an error" do
        expect{FipsLookup.fips_county(fips: "01999")}.to raise_error(StandardError, "Could not find county with fips: 999, in: AL")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county(fips: "01999", return_nil: true)).to be nil
      end
    end
  end
end
