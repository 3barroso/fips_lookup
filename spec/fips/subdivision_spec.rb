# frozen_string_literal: true

require "spec_helper"

RSpec.describe FIPS::Subdivision do
  describe ".lookup" do
    it "returns the subdivision from its full FIPS code" do
      expect(FIPS::Subdivision.lookup(fips: "0206009050")[:name]).to eq("Bristol Bay census subarea")
    end

    it "returns the subdivision from its FIPS code and state" do
      expect(FIPS::Subdivision.lookup(fips: "09050", state: "AK")[:name]).to eq("Bristol Bay census subarea")
    end

    it "returns the subdivision from state and county FIPS with a subdivision name" do
      expect(FIPS::Subdivision.lookup(fips: "02060", subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "returns the subdivision from county FIPS, state, and subdivision name" do
      expect(FIPS::Subdivision.lookup(fips: "060", state: "AK",
                                      subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "returns the subdivision from state FIPS, county name, and subdivision name" do
      expect(FIPS::Subdivision.lookup(fips: "02", county: "Bristol Bay Borough",
                                      subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "returns the subdivision from state, county, and subdivision names" do
      expect(FIPS::Subdivision.lookup(state: "Alaska", county: "Bristol Bay Borough",
                                      subdivision: "Bristol Bay census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "matches subdivision names without regard to case when given state and county FIPS" do
      expect(FIPS::Subdivision.lookup(fips: "02060", subdivision: "bRiStOl bAy census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "matches state and subdivision names without regard to case when given county FIPS" do
      expect(FIPS::Subdivision.lookup(fips: "060", state: "aK",
                                      subdivision: "bRiStOl bAy census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "matches county and subdivision names without regard to case when given state FIPS" do
      expect(FIPS::Subdivision.lookup(fips: "02", county: "bRiStOl bAy bOrOuGh",
                                      subdivision: "bRiStOl bAy census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "matches state, county, and subdivision names without regard to case" do
      expect(FIPS::Subdivision.lookup(state: "aLaSkA", county: "bRiStOl bAy bOrOuGh",
                                      subdivision: "bRiStOl bAy census subarea")[:name]).to eq("Bristol Bay census subarea")
    end

    it "raises when no subdivision matches a full FIPS code" do
      expect { FIPS::Subdivision.lookup(fips: "0206009999") }
        .to raise_error(FIPS::NotFoundError, /No subdivision found matching fips/)
    end

    it "raises when no subdivision matches a subdivision FIPS code and state" do
      expect { FIPS::Subdivision.lookup(fips: "99999", state: "AK") }
        .to raise_error(FIPS::NotFoundError, /No subdivision found matching fips/)
    end

    it "raises when no subdivision matches state and county FIPS with a subdivision name" do
      expect { FIPS::Subdivision.lookup(fips: "02099", subdivision: "Bristol Bay census subarea") }
        .to raise_error(FIPS::NotFoundError, /No subdivision found matching fips/)
    end

    it "raises when no subdivision matches county FIPS, state, and subdivision name" do
      expect { FIPS::Subdivision.lookup(fips: "999", state: "AK", subdivision: "Bristol Bay census subarea") }
        .to raise_error(FIPS::NotFoundError, /No subdivision found matching fips/)
    end

    it "raises when no subdivision matches state FIPS, county name, and subdivision name" do
      expect { FIPS::Subdivision.lookup(fips: "02", county: "Unknown Borough", subdivision: "Bristol Bay census subarea") }
        .to raise_error(FIPS::NotFoundError, /No subdivision found matching/)
    end

    it "raises when no subdivision matches state, county, and subdivision names" do
      expect { FIPS::Subdivision.lookup(state: "Alaska", county: "Bristol Bay Borough", subdivision: "Unknown census subarea") }
        .to raise_error(FIPS::NotFoundError, /No subdivision found matching/)
    end

    it "raises when no lookup parameters are provided" do
      expect { FIPS::Subdivision.lookup }
        .to raise_error(ArgumentError, /cannot determine subdivision/)
    end

    it "raises when the provided FIPS code lacks the names needed to identify a subdivision" do
      expect { FIPS::Subdivision.lookup(fips: "02") }
        .to raise_error(ArgumentError, /cannot determine subdivision/)
    end

    it "raises a not-found error for an unknown state FIPS prefix" do
      expect { FIPS::Subdivision.lookup(fips: "9900000000") }
        .to raise_error(FIPS::NotFoundError, /No state found with fips 99/)
    end

    it "rejects a non-string subdivision name" do
      expect { FIPS::Subdivision.lookup(state: "AK", county: "Bristol Bay Borough", subdivision: 9050) }
        .to raise_error(ArgumentError, /Subdivision input must be a non-empty string/)
    end

    it "rejects malformed FIPS input" do
      expect { FIPS::Subdivision.lookup(fips: "02060ABCDE") }
        .to raise_error(ArgumentError, /FIPS input must be/)
    end
  end

  describe ".all" do
    it "returns formatted subdivision records for a state" do
      expect(FIPS::Subdivision.all(state: "AK")).to include(hash_including(name: "Bristol Bay census subarea"))
    end

    it "can filter subdivision records by county name without regard to case" do
      records = FIPS::Subdivision.all(state: "AK", county: "bRiStOl bAy bOrOuGh")

      expect(records).not_to be_empty
      expect(records).to all(include(county_name: "Bristol Bay Borough"))
    end

    it "rejects a non-string county filter" do
      expect { FIPS::Subdivision.all(state: "AK", county: 60) }
        .to raise_error(ArgumentError, /County input must be a non-empty string/)
    end
  end
end
