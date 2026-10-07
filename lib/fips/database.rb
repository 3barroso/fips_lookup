# frozen_string_literal: true

require "sqlite3"

module FIPS
  module Database
    DB_PATH = File.expand_path("../data/fips.sqlite3", __dir__).freeze

    module Access
      private

      def db_all(sql, bind_params = [])
        Client.all(sql, bind_params)
      end

      def db_first(sql, bind_params = [])
        Client.first(sql, bind_params)
      end
    end

    class Client
      class << self
        def all(sql, bind_params = [])
          synchronize { connection.execute(sql, bind_params) }
        end

        def first(sql, bind_params = [])
          synchronize { connection.get_first_row(sql, bind_params) }
        end

        private

        def synchronize(&)
          mutex.synchronize(&)
        end

        def mutex
          @mutex ||= Mutex.new
        end

        def connection
          @connection ||= begin
            raise LoadError, "FIPS SQLite database is missing at #{DB_PATH}; run bin/db/build" unless File.file?(DB_PATH)

            database = SQLite3::Database.new(DB_PATH, readonly: true)
            database.results_as_hash = true
            database
          end
        end
      end
    end

    private_constant :Client
  end
end
