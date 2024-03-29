# frozen_string_literal: true

require "pathname"

RSpec.describe FipsLookup do
  it "has a version number" do
    expect(FipsLookup::VERSION).not_to be nil
  end
  let(:state_file_path) { Pathname.getwd.join("lib/data/state.csv") }

  describe ".county" do
    context "with valid state and county params" do
      it "returns the corresponding county row hash object" do
        expect(FipsLookup.county(state_param: "Al", county_name: "Autauga County")).to eq({ state_code: "AL", fips: "01001", name: "Autauga County", class_code: "H1", gnis: "00161526", status: "A" })
        expect(FipsLookup.county(state_param: "Al", county_name: "Autauga County")[:fips]).to eq("01001")
        expect(FipsLookup.county(state_param: "Al", county_name: "Autauga County")[:state_code]).to eq("AL")
        expect(FipsLookup.county(state_param: "Al", county_name: "Autauga County")[:name]).to eq("Autauga County")
        expect(FipsLookup.county(state_param: "Al", county_name: "Autauga County")[:class_code]).to eq("H1")
        expect(FipsLookup.county(state_param: "Al", county_name: "Autauga County")[:status]).to eq("A")
        expect(FipsLookup.county(state_param: "Al", county_name: "Autauga County")[:gnis]).to eq("00161526")
      end
    end

    context "with an invalid county param" do
      context "and return_nil parameter is not used" do
        it "returns an error" do
          expect{ FipsLookup.county(state_param: "Al", county_name: "Autauga") }.to raise_error(StandardError, "No county found matching: Autauga")
        end
      end
      context "and return_nil parameter is used" do
        it "returns an empty hash object" do
          expect(FipsLookup.county(state_param: "Alabama", county_name: "Autauga", return_nil: true)).to eq({})
        end
      end
    end

    context "with an invalid state param" do
      context "and return_nil parameter is not used" do
        it "returns an error" do
          expect { FipsLookup.county(state_param: "ZZ", county_name: "County") }.to raise_error(StandardError, "No state found matching: ZZ")
        end
      end
      context "and return_nil parameter is used" do
        it "returns nil" do
          expect(FipsLookup.county(state_param: "ZZ", county_name: "County", return_nil: true)).to eq({})
        end
      end
    end

    context "as .county is called" do
      it "populates a memoized hash attribute accessor @county_fips with state code and county parameter as lookups" do
        expect(FipsLookup.county(state_param: "AL", county_name: "Autauga County")[:fips]).to eq("01001")

        lookup = ["AL", "Autauga County".upcase]
        expect(FipsLookup.county_fips[lookup][:fips]).to eq("01001")
      end
    end
  end

  describe ".state" do
    context "with valid state param" do
      it "returns the corresponding state row hash" do
        expect(FipsLookup.state(state_param: "AL")).to eq({ ansi: "01779775", code: "AL", fips: "01", name: "Alabama" })
        expect(FipsLookup.state(state_param: "AL")[:code]).to eq("AL")
        expect(FipsLookup.state(state_param: "AL")[:ansi]).to eq("01779775")
        expect(FipsLookup.state(state_param: "AL")[:fips]).to eq("01")
        expect(FipsLookup.state(state_param: "AL")[:name]).to eq("Alabama")
      end
    end

    context "with an invalid state param" do
      context "when return_nil parameter is not used" do
        it "returns an error" do
          expect{FipsLookup.state(state_param: "BC")}.to raise_error(StandardError, "No state found matching: BC")
        end
      end
      context "when return_nil parameter is used" do
        it "returns an empty dictionary" do
          expect(FipsLookup.state(state_param: "BC", return_nil: true)).to eq({})
        end
      end
    end
    context "as .state is called the state_fips class attribute grows" do
      it "with state param as key" do
        expect(FipsLookup.state_fips["AL"]).to eq({ ansi: "01779775", code: "AL", fips: "01", name: "Alabama" })
      end

      context "when the state cannot be found, but return_nil is used, empty objects are created" do
        it "stores state param lookup as key when .county is called" do
          expect(FipsLookup.state_fips["ZZ"]).to eq ({})
          expect(FipsLookup.state_fips["BC"]).to eq ({})
        end
      end
    end
  end

  describe "STATE_CODES" do
    it "is a hash with the same number of key value pairs as rows in the state.csv file" do
      expect(FipsLookup::STATE_CODES.length).to eq(`wc -l #{state_file_path}`.to_i)
    end
  end

  describe ".fips_county" do
    it "takes in a 5 digit code and finds the corresponding state county name" do
      expect(FipsLookup.fips_county(fips: "01001")).to eq(["Autauga County", "AL"])
    end

    context "when the input is not valid" do
      it "returns an error" do
        expect { FipsLookup.fips_county(fips: 12_345) }.to raise_error(StandardError, "FIPS input must be 5 digit string")
        expect { FipsLookup.fips_county(fips: "123") }.to raise_error(StandardError, "FIPS input must be 5 digit string")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county(fips: 12_345, return_nil: true)).to be nil
        expect(FipsLookup.fips_county(fips: "123", return_nil: true)).to be nil
      end
    end

    context "when the input is valid but state code cannot be found" do
      it "returns an error" do
        expect { FipsLookup.fips_county(fips: "03123") }.to raise_error(StandardError, "No state found matching: 03")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county(fips: "03123", return_nil: true)).to be nil
      end
    end

    context "when the input is valid but county can not be found" do
      it "returns an error" do
        expect { FipsLookup.fips_county(fips: "01999") }.to raise_error(StandardError, "Could not find county with fips: 999, in: AL")
      end

      it "returns nil if optional parameter is true" do
        expect(FipsLookup.fips_county(fips: "01999", return_nil: true)).to be nil
      end
    end
  end

  describe ".find_state_code" do
    context "when valid input is entered" do
      it "checks for state as numeric input, 2 char abbriviation, name or geoid and returns the state code" do
        expect(FipsLookup.find_state_code(state_param: "MI")).to eq("MI")
        expect(FipsLookup.find_state_code(state_param: "26")).to eq("MI")
        expect(FipsLookup.find_state_code(state_param: "MicHiGan")).to eq("MI")
        expect(FipsLookup.find_state_code(state_param: "01779789")).to eq("MI")
      end
    end

    context "when invalid input is entered and return_nil is not specified" do
      it "returns nil after checking for state as numeric input, 2 char abbriviation, name or geoid" do
        expect { FipsLookup.find_state_code(state_param: "MM") }.to raise_error(StandardError, "No state found matching: MM")
        expect { FipsLookup.find_state_code(state_param: "43") }.to raise_error(StandardError, "No state found matching: 43")
        expect { FipsLookup.find_state_code(state_param: "MMicHiGan") }.to raise_error(StandardError, "No state found matching: MMicHiGan")
        expect { FipsLookup.find_state_code(state_param: "10779789") }.to raise_error(StandardError, "No state found matching: 10779789")
      end
    end

    context "when invalid input is entered and return_nil is specified as true" do
      it "returns nil after checking for state as numeric input, 2 char abbriviation, name or geoid" do
        expect(FipsLookup.find_state_code(state_param: "MM", return_nil: true)).to eq nil
        expect(FipsLookup.find_state_code(state_param: "43", return_nil: true)).to eq nil
        expect(FipsLookup.find_state_code(state_param: "MMicHiGan", return_nil: true)).to eq nil
        expect(FipsLookup.find_state_code(state_param: "10779789", return_nil: true)).to eq nil
      end
    end
  end

  describe ".county_file" do
    context "when valid state code is used" do
      it "returns the path to the county file" do
        expect(FipsLookup.county_file(state_code: "MI")).to include("data/county/MI.csv")
      end
    end
    context "when invalid state code is used" do
      it "returns the path to the county file" do
        expect(FipsLookup.county_file(state_code: "ZZ")).to be nil
      end
    end
  end

  describe ".state_file" do
    it "returns the path to state.csv file as a string" do
      expect(FipsLookup.state_file).to include(state_file_path.to_s)
    end
  end
end
