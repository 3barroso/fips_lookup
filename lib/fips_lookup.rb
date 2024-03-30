# frozen_string_literal: true

require_relative "fips_lookup/version"
require "csv"

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

    def county(state_param:, county_param:, return_nil: false)
      state_code = find_state_code(state_param: state_param, return_nil: return_nil)
      return {} if state_code.nil?

      lookup = [state_code, county_param.upcase]
      @county_fips ||= {}
      @county_fips[lookup] ||= county_lookup(state_code, county_param, return_nil)
    end

    def state(state_param:, return_nil: false)
      @state_fips ||= {}
      @state_fips[state_param] ||= state_lookup(state_param, return_nil)
    end

    def fips_county(fips:, return_nil: false)
      unless fips.is_a?(String) && fips.length == 5
        return_nil ? (return nil) : (raise StandardError, "FIPS input must be 5 digit string")
      end

      state_code = find_state_code(state_param: fips[0..1], return_nil: return_nil)
      return nil if state_code.nil?

      CSV.foreach(county_file(state_code: state_code)) do |county_row|
        # state_code (AL), state fips (01), county fips (001), county gnis(00161526), name (Augtauga County), class code (H1), status (A)
        return [county_row[4], state_code] if county_row[2] == fips[2..4]
      end

      raise StandardError, "Could not find county with fips: #{fips[2..4]}, in: #{state_code}" unless return_nil
    end

    def find_state_code(state_param:, return_nil: false)
      return state_param.upcase if STATE_CODES.key?(state_param.upcase)
      return STATE_CODES.key(state_param) if STATE_CODES.value?(state_param)

      state(state_param: state_param, return_nil: return_nil)[:code]
    end

    def county_file(state_code:)
      file_path = "#{File.expand_path(__dir__)}/data/county/#{state_code}.csv"
      file_path if File.exist?(file_path)
    end

    def state_file
      "#{File.expand_path(__dir__)}/data/state.csv"
    end

    private

    def county_lookup(state_code, county_param, return_nil)
      upcase_param = county_param.upcase
      CSV.foreach(county_file(state_code: state_code)) do |county_row|
        if county_match_row?(county_row, upcase_param)
          return { state_code: county_row[0], fips: (county_row[1] + county_row[2]), gnis: county_row[3],
                   name: county_row[4], class_code: county_row[5], status: county_row[6] }
        end
      end
      return_nil ? (return {}) : (raise StandardError, "No county found matching: #{county_param}" unless return_nil)
    end

    def county_match_row?(row, param)
      # row => state (AL), state fips (01), county fips (001), county gnis (00161526), name (Augtauga County), class code (H1), status (A)
      row[4].upcase == param || row[3] == param || row[2] == param || "#{row[1]}#{row[2]}" == param
    end

    def state_lookup(state_param, return_nil = false)
      upstate_param = state_param.upcase
      CSV.foreach(state_file) do |state_row|
        if state_match_row?(state_row, upstate_param)
          return { fips: state_row[0], code: state_row[1], name: state_row[2], ansi: state_row[3] }
        end
      end
      return_nil ? (return {}) : (raise StandardError, "No state found matching: #{state_param}")
    end

    def state_match_row?(row, param)
      # row => state fips (01), state code (AL), state name (Alabama), ansi (01779775)
      row[0] == param || row[1] == param || row[2].upcase == param || row[3] == param
    end
  end
end
