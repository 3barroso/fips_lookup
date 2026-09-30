# frozen_string_literal: true

require "pathname"

RSpec.describe FIPS do
  it "has a version number" do
    expect(FIPS::VERSION).not_to be nil
  end

  describe ".lookup" do
    it "dispatches a 2-digit FIPS code to the state lookup" do
      expect(FIPS.lookup(fips: "02")[:name]).to eq("Alaska")
    end

    it "dispatches state input to the state lookup" do
      expect(FIPS.lookup(state: "Alaska")[:abbr]).to eq("AK")
    end

    it "dispatches a 5-digit FIPS code to the county lookup" do
      expect(FIPS.lookup(fips: "02060")[:name]).to eq("Bristol Bay Borough")
    end

    it "dispatches a 3-digit county FIPS and state to the county lookup" do
      expect(FIPS.lookup(fips: "060", state: "AK")[:name]).to eq("Bristol Bay Borough")
    end

    it "dispatches a 2-digit state FIPS and county name to the county lookup" do
      expect(FIPS.lookup(fips: "02", county: "Bristol Bay Borough")[:name]).to eq("Bristol Bay Borough")
    end

    it "dispatches state and county names to the county lookup" do
      expect(FIPS.lookup(state: "Alaska", county: "Bristol Bay Borough")[:fips]).to eq("02060")
    end

    it "dispatches a 10-digit FIPS code to the subdivision lookup" do
      expect(FIPS.lookup(fips: "0206009050")[:name]).to eq("Bristol Bay census subarea")
    end

    it "dispatches a 5-digit subdivision FIPS and state to the subdivision lookup" do
      expect(FIPS.lookup(fips: "09050", state: "AK")[:name]).to eq("Bristol Bay census subarea")
    end

    it "dispatches a 5-digit state-and-county FIPS and subdivision name to the subdivision lookup" do
      expect(FIPS.lookup(fips: "02060", subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "dispatches a 3-digit county FIPS, state, and subdivision name to the subdivision lookup" do
      expect(FIPS.lookup(fips: "060", state: "AK", subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "dispatches a 2-digit state FIPS, county name, and subdivision name to the subdivision lookup" do
      expect(FIPS.lookup(fips: "02", county: "Bristol Bay Borough", subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "dispatches state, county, and subdivision names to the subdivision lookup" do
      expect(FIPS.lookup(state: "Alaska", county: "Bristol Bay Borough", subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "raises for a non-string FIPS input" do
      expect { FIPS.lookup(fips: 2) }
        .to raise_error(ArgumentError, /FIPS input must be a string/)
    end

    it "raises for an unsupported FIPS length" do
      expect { FIPS.lookup(fips: "1234") }
        .to raise_error(ArgumentError, /FIPS code/)
    end

    it "raises when no lookup parameters are provided" do
      expect { FIPS.lookup }
        .to raise_error(ArgumentError, /Insufficient parameters/)
    end

    it "raises when parameters do not identify one lookup type" do
      expect { FIPS.lookup(county: "Bristol Bay Borough") }
        .to raise_error(ArgumentError, /Insufficient parameters/)
    end
  end
end
