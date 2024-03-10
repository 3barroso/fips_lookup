# frozen_string_literal: true

require_relative "fips_lookup/version"
require 'csv'
require 'pathname'

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
                  "PR" => "72", "UM" => "74", "VI" => "78"
                }.freeze

  class << self
    attr_accessor :county_fips

    def county(state_param, county_name_param, return_nil = false)
      lookup = [state_param.upcase, county_name_param.upcase]
      @county_fips ||= {}
      @county_fips[lookup] ||= county_lookup(state_param, county_name_param, return_nil)
    end

    def county_lookup(state_param, county_name_param, return_nil = false)
      state_code = find_state_code(state_param, return_nil)
      return nil if state_code.nil?

      CSV.foreach(state_county_file(state_code)) do |county_row|
        # county_row = state (AL), state code (01), county fips (001), county name (Augtauga County), county class code (H1)
        if county_row[3].upcase == county_name_param.upcase
          return county_row[1] + county_row[2]
        end
      end

      raise StandardError, "No county found matching: #{county_name_param}" unless return_nil
    end

    def find_state_code(state_param, return_nil = false)
      return state_param.upcase if STATE_CODES.key?(state_param.upcase)
      return STATE_CODES.key(state_param) if STATE_CODES.value?(state_param)

      CSV.foreach(state_file) do |state_row|
        # state_row = state code (01), state postal code (AL), state name (Alabama), state ansi code (01779775)
        if state_param.upcase == state_row[2].upcase || state_param == state_row[3]
          return state_row[1]
        end
      end

      raise StandardError, "No state found matching: #{state_param}" unless return_nil
    end

    def fips_county(fips_param, return_nil = false)
      unless fips_param.is_a?(String) && fips_param.length == 5
        return_nil ? (return nil) : (raise StandardError, "FIPS input must be 5 digit string")
      end
      state_code = STATE_CODES.key(fips_param[0..1])

      if state_code.nil?
        return_nil ? (return nil) : (raise StandardError, "Could not find state with FIPS: #{fips_param[0..1]}")
      end

      CSV.foreach(state_county_file(state_code)) do |county_row|
        if county_row[2] == fips_param[2..4]
          return [county_row[3], state_code]
        end
      end

      raise StandardError, "Could not find #{state_code} county matching FIPS: #{fips_param[2..4]}" unless return_nil
    end

    private

    def state_county_file(state_code)
      Pathname.getwd + "lib/county/#{state_code}.csv"
    end

    def state_file
      Pathname.getwd + "lib/state.csv"
    end
  end
end
