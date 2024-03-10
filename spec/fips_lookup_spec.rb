# frozen_string_literal: true
require 'pathname'

RSpec.describe FipsLookup do
  it "has a version number" do
    expect(FipsLookup::VERSION).not_to be nil
  end

  describe ".county_lookup" do
    context "with searchable state and county params" do
      it "returns the proper fips code" do
        expect(FipsLookup.county_lookup("Al", "Autauga County")).to eq("01001")
      end
    end

    context "with an invalid county param" do
      context "and return_nil parameter is not used" do
        it "returns an error" do
          expect{FipsLookup.county_lookup("AL", "Autauga")}.to raise_error(StandardError, "No county found matching: Autauga")
        end
      end
      context "and return_nil parameter is used" do
        it "returns nil" do
          expect(FipsLookup.county_lookup("Alabama", "Autauga", true)).to eq(nil)
        end
      end
    end

    context "with an invalid state param" do
      context "and return_nil parameter is not used" do
        it "returns an error" do
          expect{FipsLookup.county_lookup("ZZ", "County")}.to raise_error(StandardError, "No state found matching: ZZ")
        end
      end
      context "and return_nil parameter is used" do
        it "returns nil" do
          expect(FipsLookup.county_lookup("ZZ", "County", true)).to eq(nil)
        end
      end
    end
  end

  describe ".county" do
    it "populates a memoized hash attribute accessor with state parameter and county parameter as lookups" do
      expect(FipsLookup.county("AL", "Autauga County")).to eq("01001")

      lookup = ["AL".upcase, "Autauga County".upcase]
      expect(FipsLookup.county_fips[lookup]).to eq("01001")
    end
  end

  describe "STATE_CODES" do
    it "is a hash with the same number of key value pairs as rows in the state.csv file" do
      state_file_path = Pathname.getwd + "lib/state.csv"
      expect(FipsLookup::STATE_CODES.length - 1).to eq(`wc -l #{state_file_path}`.to_i)
    end
  end

  describe ".fips_county" do
    it "takes in a 5 digit code and finds the corresponding state county name" do
      expect(FipsLookup.fips_county("01001")).to eq(["Autauga County", "AL"])
    end

    context "when the input is not valid" do
      it "returns an error" do
        expect{FipsLookup.fips_county(12345)}.to raise_error(StandardError, "FIPS input must be 5 digit string")
        expect{FipsLookup.fips_county("123")}.to raise_error(StandardError, "FIPS input must be 5 digit string")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county(12345, true)).to be nil
        expect(FipsLookup.fips_county("123", true)).to be nil
      end
    end

    context "when the input is valid but state code cannot be found" do
      it "returns an error" do
        expect{FipsLookup.fips_county("03123")}.to raise_error(StandardError, "Could not find state with FIPS: 03")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county("03123", true)).to be nil
      end
    end

    context "when the input is valid but county can not be found" do
      it "returns an error" do
        expect{FipsLookup.fips_county("01999")}.to raise_error(StandardError, "Could not find AL county matching FIPS: 999")

      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county("01999", true)).to be nil
      end
    end
  end
end
