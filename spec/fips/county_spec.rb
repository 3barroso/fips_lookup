# frozen_string_literal: true

require "spec_helper"

RSpec.describe FIPS::County do
  describe ".lookup" do
    it "returns the county from its full FIPS code" do
      expect(FIPS::County.lookup(fips: "02060")[:name]).to eq("Bristol Bay Borough")
    end

    it "returns the county from county FIPS and state" do
      expect(FIPS::County.lookup(fips: "060", state: "AK")[:name]).to eq("Bristol Bay Borough")
    end

    it "returns the county from state FIPS and county name" do
      expect(FIPS::County.lookup(fips: "02", county: "Bristol Bay Borough")[:name]).to eq("Bristol Bay Borough")
    end

    it "returns the county from state and county names" do
      expect(FIPS::County.lookup(state: "Alaska", county: "Bristol Bay Borough")[:name]).to eq("Bristol Bay Borough")
    end

    it "matches county names without regard to case when given state FIPS" do
      expect(FIPS::County.lookup(fips: "02", county: "bRiStOl bAy bOrOuGh")[:name]).to eq("Bristol Bay Borough")
    end

    it "matches state and county names without regard to case" do
      expect(FIPS::County.lookup(state: "aLaSkA", county: "bRiStOl bAy bOrOuGh")[:name]).to eq("Bristol Bay Borough")
    end

    it "matches a mixed-case state name with county FIPS" do
      expect(FIPS::County.lookup(fips: "060", state: "aK")[:name]).to eq("Bristol Bay Borough")
    end

    it "raises when no county matches a full FIPS code" do
      expect { FIPS::County.lookup(fips: "02999") }
        .to raise_error(FIPS::NotFoundError, /Could not identify county with fips/)
    end

    it "raises when no county matches county FIPS and state" do
      expect { FIPS::County.lookup(fips: "999", state: "AK") }
        .to raise_error(FIPS::NotFoundError, /Could not identify county with fips/)
    end

    it "raises when no county matches state FIPS and county name" do
      expect { FIPS::County.lookup(fips: "02", county: "Unknown Borough") }
        .to raise_error(FIPS::NotFoundError, /Could not identify county with name/)
    end

    it "raises when no county matches state and county names" do
      expect { FIPS::County.lookup(state: "Alaska", county: "Unknown Borough") }
        .to raise_error(FIPS::NotFoundError, /Could not identify county with name/)
    end

    it "raises when no lookup parameters are provided" do
      expect { FIPS::County.lookup }
        .to raise_error(ArgumentError, /Could not identify county/)
    end

    it "raises when the provided FIPS code lacks the county identifier" do
      expect { FIPS::County.lookup(fips: "02") }
        .to raise_error(ArgumentError, /Could not identify county/)
    end

    it "raises a not-found error for an unknown state FIPS prefix" do
      expect { FIPS::County.lookup(fips: "99000") }
        .to raise_error(FIPS::NotFoundError, /No state found with code 99/)
    end

    it "rejects a non-string county name" do
      expect { FIPS::County.lookup(state: "AK", county: 60) }
        .to raise_error(ArgumentError, /County input must be a non-empty string/)
    end

    it "rejects malformed FIPS input" do
      expect { FIPS::County.lookup(fips: "12A45") }
        .to raise_error(ArgumentError, /FIPS input must be/)
    end
  end

  describe ".file" do
    it "returns the path to the county csv of the given state" do
      expect(FIPS::County.file("MI")).to include("lib/data/county/MI.csv")
    end
  end

  describe ".all" do
    it "returns formatted county records for a state identifier" do
      expect(FIPS::County.all(state: "AK")).to include(hash_including(name: "Bristol Bay Borough", fips: "02060"))
    end

    it "rejects a blank state identifier" do
      expect { FIPS::County.all(state: " ") }
        .to raise_error(ArgumentError, /State input must be a non-empty string/)
    end
  end
end
