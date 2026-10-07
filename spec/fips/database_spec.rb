# frozen_string_literal: true

require "spec_helper"

RSpec.describe FIPS::Database::Access do
  let(:query_host) { Class.new { extend FIPS::Database::Access } }
  let(:client) { FIPS::Database.const_get(:Client, false) }

  it "keeps SQL helper methods private on the lookup class" do
    expect(query_host.respond_to?(:db_all)).to be(false)
    expect(query_host.respond_to?(:db_first)).to be(false)
  end

  describe "private db_first helper" do
    it "raises a clear error when the database file is missing" do
      cached_connection = client.instance_variable_get(:@connection)
      client.instance_variable_set(:@connection, nil)
      allow(File).to receive(:file?).and_call_original
      allow(File).to receive(:file?).with(FIPS::Database::DB_PATH).and_return(false)

      expect { query_host.send(:db_first, "SELECT 1") }
        .to raise_error(LoadError, /FIPS SQLite database is missing/)
    ensure
      client.instance_variable_set(:@connection, cached_connection)
    end

    it "binds supplied values as data rather than SQL" do
      payload = "' OR 1=1 --"

      expect(query_host.send(:db_first, "SELECT ? AS value", [payload]))
        .to eq("value" => payload)
      expect(query_host.send(:db_first, "SELECT name FROM states WHERE name_key = ?", [payload])).to be_nil
    end
  end

  describe "private db_all helper" do
    it "opens the database read-only" do
      expect { query_host.send(:db_all, "CREATE TABLE should_not_be_created (id INTEGER)") }
        .to raise_error(SQLite3::ReadOnlyException, /readonly|read-only/i)
    end
  end
end
