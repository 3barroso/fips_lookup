# frozen_string_literal: true

require "sqlite3"
require "thread"

module FIPS
  module Database
    DB_PATH = File.expand_path("../data/fips.sqlite3", __dir__).freeze

    class << self
      def all(sql, bind_vars = [])
        synchronize { connection.execute(sql, bind_vars) }
      end

      def first(sql, bind_vars = [])
        synchronize { connection.get_first_row(sql, bind_vars) }
      end

      private

      def synchronize(&block)
        mutex.synchronize(&block)
      end

      def mutex
        @mutex ||= Mutex.new
      end

      def connection
        @connection ||= begin
          unless File.file?(DB_PATH)
            raise LoadError, "FIPS SQLite database is missing at #{DB_PATH}; run bin/db/build"
          end

          database = SQLite3::Database.new(DB_PATH, readonly: true)
          database.results_as_hash = true
          database
        end
      end
    end
  end
end