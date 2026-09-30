# frozen_string_literal: true

require "spec_helper"

RSpec.describe FIPS::State do
  describe "ABBR_CODES" do
    it "is a hash with the same number of key value pairs as rows in the state.csv file" do
      expect(FIPS::State::ABBR_CODES.length).to eq(`wc -l #{state_file_path}`.to_i)
    end
  end

  let(:state_file_path) { Pathname.getwd.join("lib/data/state.csv") }
  describe ".file" do
    it "returns the path to state.csv file as a string" do
      expect(FIPS::State.file).to include(state_file_path.to_s)
    end
  end

  describe ".lookup" do
    it "returns the state from its two-digit FIPS code" do
      expect(FIPS::State.lookup(fips: "02")[:name]).to eq("Alaska")
    end

    it "returns the state from its abbreviation" do
      expect(FIPS::State.lookup(state: "AK")[:name]).to eq("Alaska")
    end

    it "returns the state from its full name" do
      expect(FIPS::State.lookup(state: "Alaska")[:abbr]).to eq("AK")
    end

    it "returns the state from its FIPS code passed as state" do
      expect(FIPS::State.lookup(state: "02")[:name]).to eq("Alaska")
    end

    it "returns the state from its ANSI code" do
      expect(FIPS::State.lookup(state: "01785533")[:name]).to eq("Alaska")
    end

    it "matches state abbreviations and names without regard to case" do
      expect(FIPS::State.lookup(state: "aLaSkA")[:abbr]).to eq("AK")
      expect(FIPS::State.lookup(state: "ak")[:name]).to eq("Alaska")
    end

    it "raises when no state matches a valid-length FIPS code" do
      expect { FIPS::State.lookup(fips: "99") }
        .to raise_error(FIPS::NotFoundError, /No state found with fips 99/)
    end

    it "raises when the FIPS input is not a two-digit string" do
      expect { FIPS::State.lookup(fips: "2") }
        .to raise_error(ArgumentError, /FIPS input must be a 2 digit string/)
    end

    it "rejects non-digit FIPS input" do
      expect { FIPS::State.lookup(fips: "A2") }
        .to raise_error(ArgumentError, /FIPS input must be a 2 digit string/)
    end

    it "raises when no state matches the provided state identifier" do
      expect { FIPS::State.lookup(state: "Atlantis") }
        .to raise_error(FIPS::NotFoundError, /No state found matching: Atlantis/)
    end

    it "raises when the state input is not a string" do
      expect { FIPS::State.lookup(state: 2) }
        .to raise_error(ArgumentError, /State input must be a non-empty string/)
    end

    it "raises when no lookup parameters are provided" do
      expect { FIPS::State.lookup }
        .to raise_error(ArgumentError, /Could not identify state/)
    end
  end
end
