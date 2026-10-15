# frozen_string_literal: true

require "csv"

# FIPS::State
module FIPS
  class State
    ABBR_CODES = { "AL" => "01", "AK" => "02", "AZ" => "04", "AR" => "05", "CA" => "06", "CO" => "08",
                   "CT" => "09", "DE" => "10", "DC" => "11", "FL" => "12", "GA" => "13", "HI" => "15",
                   "ID" => "16", "IL" => "17", "IN" => "18", "IA" => "19", "KS" => "20", "KY" => "21",
                   "LA" => "22", "ME" => "23", "MD" => "24", "MA" => "25", "MI" => "26", "MN" => "27",
                   "MS" => "28", "MO" => "29", "MT" => "30", "NE" => "31", "NV" => "32", "NH" => "33",
                   "NJ" => "34", "NM" => "35", "NY" => "36", "NC" => "37", "ND" => "38", "OH" => "39",
                   "OK" => "40", "OR" => "41", "PA" => "42", "RI" => "44", "SC" => "45", "SD" => "46",
                   "TN" => "47", "TX" => "48", "UT" => "49", "VT" => "50", "VA" => "51", "WA" => "53",
                   "WV" => "54", "WI" => "55", "WY" => "56", "AS" => "60", "GU" => "66", "MP" => "69",
                   "PR" => "72", "UM" => "74", "VI" => "78" }.freeze

    class << self
      def abbr_to_fips(abbr)
        ABBR_CODES[abbr&.to_s&.upcase]
      end

      def fips_to_abbr(fips)
        ABBR_CODES.key(fips&.to_s)
      end

      def lookup(**params)
        fips = params.fetch(:fips, nil)
        state = params.fetch(:state, nil)

        state_row = raw_csv.find { |row| row.include?(fips) || row.include?(state) }

        return formatted_state(state_row) unless state_row.nil?

        raw_csv.each do |row|
          return formatted_state(row) if row[0] == fips || row[1].casecmp?(state) || row[2].casecmp?(state) || row[3] == state
        end

        raise ArgumentError, "Could not identify state with parameters provided: #{params.inspect}"
      end

      def all
        raw_csv.map { |row| formatted_state(row) }
      end

      def raw_csv
        @raw_csv ||= CSV.read(file_path)
      end

      private

      def file_path
        File.expand_path("../data/state.csv", __dir__)
      end

      def formatted_state(row)
        {
          fips: row[0],
          abbr: row[1],
          name: row[2],
          ansi: row[3]
        }
      end
    end
  end
end
