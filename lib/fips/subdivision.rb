# frozen_string_literal: true

# FIPS::Subdivision
module FIPS
  class Subdivision

    def self.lookup(**params)
      fips = params.fetch(:fips, nil)
      state = params.fetch(:state, nil)
      county = params.fetch(:county, nil)
      subdivision = params.fetch(:subdivision, nil)

      # ensure the state can be determined from the provided parameters ? (set as a variable state_abbr) # set_state(params) method?

      location = identify_with_fips(fips, state, county, subdivision)
      return location unless location.nil?
      

      if [:state, :county, :subdivision].all? { |key| !params[key].nil? }
        return by_name(state, county, subdivision)
      end
      raise StandardError, "cannot determine subdivision: no valid parameters provided"
    end

    def self.subdivision1(state_param:, subdivision_param:, return_nil: false)
      state_code = FIPS::State.find_state_code(state_param: state_param, return_nil: return_nil)
      return {} if state_code.nil?

      lookup = [state_code, subdivision_param.upcase]
      subdivision_cache = FIPS.subdivision_fips ||= {}
      subdivision_cache[lookup] ||= subdivision_lookup(state_code, subdivision_param, return_nil)
    end

    def self.file(state_abbr)
      file_path = "#{File.expand_path("..", __dir__)}/data/subdivision/#{state_abbr}.csv"
      file_path if File.exist?(file_path)
    end

    private

    def self.identify_with_fips(fips, state, county, subdivision)
      return nil if fips.nil? || !fips.is_a?(String)
      valid_lengths = [2, 3, 5, 10]
      return nil unless valid_lengths.include?(fips.length)

      case fips.length
      when 2
        # fips identifies state, need county and subdivision names
        return nil if county.nil? || subdivision.nil?
        state_abbr = FIPS::State.state_abbr(fips)
        return by_name(state_abbr, county, subdivision)
      when 3
        # fips identifies county, need state and subdivision names
        return nil if state.nil? || subdivision.nil?
        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        return by_county_fips_state_and_sub_name(fips, state_abbr, subdivision)
      when 5
        # fips identifies subdivision (5-digit) or state (2-digit) & county (3-digit)
        if subdivision.nil? 
          # fips identifies the subdivision, need state
          return nil if state.nil?
          return by_state_and_sub_fips(state, fips)
        else
          # fips identifies state & county
          return by_fips_and_sub_name(fips, subdivision)
        end
      when 10
        # fips identifies the full subdivision
        return by_fips(fips)
      else
        return nil
      end
    end

    def self.by_state_and_sub_fips(state, fips)
      # find subdivision based on fips code (5-digit) with inputted state
      state_abbr = FIPS::State.lookup(state: state)[:abbr]
      subdivision_file = self.file(state_abbr)
      CSV.foreach(subdivision_file) do |subdivision_row|
        return formatted_subdivision(subdivision_row) if subdivision_row[4] == fips
      end
      raise StandardError, "No subdivision found matching fips: #{fips}"
    end

    def self.by_fips_and_sub_name(fips, subdivision)
      # find subdivision based on fips code and subdivision name
      upcase_sub = subdivision.upcase
      state_abbr = FIPS::State.state_abbr(fips[0, 2])
      subdivision_file = self.file(state_abbr)
      CSV.foreach(subdivision_file) do |subdivision_row|
        return formatted_subdivision(subdivision_row) if subdivision_row[2] == fips[2, 3] && subdivision_row[6].upcase == upcase_sub
      end
      raise StandardError, "No subdivision found matching fips: #{fips} and name: #{subdivision}"
    end

    def self.by_county_fips_state_and_sub_name(fips, state_abbr, subdivision)
      # find subdivision based on county fips, state, and subdivision name
      sub_upcase = subdivision.upcase
      CSV.foreach(self.file(state_abbr)) do |subdivision_row|
        return formatted_subdivision(subdivision_row) if subdivision_row[2] == fips && subdivision_row[6].upcase == sub_upcase
      end
      raise StandardError, "No subdivision found matching county fips: #{fips}, state: #{state_abbr}, and name: #{subdivision}"
    end
      
    def self.by_fips(fips)
      state_code = fips[0, 2]
      county_fips = fips[2, 3]
      subdivision_fips = fips[5, 5]
      state_abbr = FIPS::State.state_abbr(state_code)

      subdivision_file = self.file(state_abbr)
      CSV.foreach(subdivision_file) do |subdivision_row|
        return formatted_subdivision(subdivision_row) if subdivision_row[1] + subdivision_row[2] + subdivision_row[4] == fips
      end
      raise StandardError, "No subdivision found matching fips: #{fips}"
    end

    def self.by_name(state, county, subdivision)
      state_abbr = FIPS::State.lookup(state: state)[:abbr]
      sub_upcase = subdivision.upcase
      county_upcase = county.upcase

      subdivision_file = self.file(state_abbr)
      CSV.foreach(subdivision_file) do |subdivision_row|
        # match must be for subdivision and county name
        return formatted_subdivision(subdivision_row) if subdivision_row[3].upcase == county_upcase && subdivision_row[6].upcase == sub_upcase
      end
      raise StandardError, "No subdivision found matching: #{subdivision} in #{county}"
    end

    def self.formatted_subdivision(row)
      # row => state_code (AL), state fips (01), county fips (001), county name (Augtauga County)
      #   row => subdivision fips (12345), gnis (12345678), 
      #   row => subdivision name(Autaugaville CCD), class code (Z5), status (S)
      {
        state_abbr: row[0],
        fips: row[1] + row[2] + row[4],
        county_name: row[3],
        gnis: row[5],
        name: row[6],
        class_code: row[7],
        status: row[8]
      }
    end
  end
end
