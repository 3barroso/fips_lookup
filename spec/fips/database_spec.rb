# frozen_string_literal: true

require "spec_helper"

RSpec.describe FIPS::Database do
  describe ".first" do
    it "raises a clear error when the database file is missing" do
      cached_connection = described_class.instance_variable_get(:@connection)
      described_class.instance_variable_set(:@connection, nil)
      allow(File).to receive(:file?).and_call_original
      allow(File).to receive(:file?).with(described_class::DB_PATH).and_return(false)

      expect { described_class.first("SELECT 1") }
        .to raise_error(LoadError, /FIPS SQLite database is missing/)
    ensure
      described_class.instance_variable_set(:@connection, cached_connection)
    end

    it "binds supplied values as data rather than SQL" do
      payload = "' OR 1=1 --"

      expect(described_class.first("SELECT ? AS value", [payload]))
        .to eq("value" => payload)
      expect(described_class.first("SELECT name FROM states WHERE name_key = ?", [payload])).to be_nil
    end
  end

  describe ".all" do
    it "opens the database read-only" do
      expect { described_class.all("CREATE TABLE should_not_be_created (id INTEGER)") }
        .to raise_error(SQLite3::ReadOnlyException, /readonly|read-only/i)
    end
  end
end
