# frozen_string_literal: true

require "csv"
require_relative "fips_lookup/version"
require_relative "fips_lookup/county"

# worker for county, state, fips lookups
module FipsLookup
  STATE_CODES = { "AL" => "01", "AK" => "02", "AZ" => "04", "AR" => "05", "CA" => "06", "CO" => "08",
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
    attr_accessor :county_fips, :state_fips

    def state(state_param:, return_nil: false)
      @state_fips ||= {}
      @state_fips[state_param] ||= state_lookup(state_param, return_nil)
    end

    def find_state_code(state_param:, return_nil: false)
      return state_param.upcase if STATE_CODES.key?(state_param.upcase)
      return STATE_CODES.key(state_param) if STATE_CODES.value?(state_param)

      state(state_param: state_param, return_nil: return_nil)[:code]
    end

    def state_file
      "#{File.expand_path(__dir__)}/data/state.csv"
    end

    private

    def state_lookup(state_param, return_nil = false)
      upstate_param = state_param.upcase
      CSV.foreach(state_file) do |state_row|
        return formatted_state(state_row) if state_match_row?(state_row, upstate_param)
      end
      return_nil ? (return {}) : (raise StandardError, "No state found matching: #{state_param}")
    end

    def state_match_row?(row, param)
      # row => state fips (01), state code (AL), state name (Alabama), ansi (01779775)
      row[0] == param || row[1] == param || row[2].upcase == param || row[3] == param
    end

    def formatted_state(row)
      {
        fips: row[0],
        code: row[1],
        name: row[2],
        ansi: row[3]
      }
    end
  end
end
