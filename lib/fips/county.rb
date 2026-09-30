# frozen_string_literal: true

# FIPS::County
module FIPS
  class County
    def self.lookup(**params)
      fips = params.fetch(:fips, nil)
      state = params.fetch(:state, nil)
      county = params.fetch(:county, nil)

      location = identify_with_fips(fips, state, county)
      return location unless location.nil?

      if !county.nil? && !state.nil?
        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        return by_name(state_abbr, county)
      end

      raise StandardError, "Could not identify county with parameters provided: #{params.inspect}"
    end

    def self.county1(state_param:, county_param:, return_nil: false)
      state_code = FIPS::State.find_state_code(state_param: state_param, return_nil: return_nil)
      return {} if state_code.nil?

      lookup = [state_code, county_param.upcase]
      county_cache = FIPS.county_fips ||= {}
      county_cache[lookup] ||= county_lookup(state_code, county_param, return_nil, county_cache)
    end

    def self.fips_county(fips:, return_nil: false)
      unless fips.is_a?(String) && fips.length == 5
        return_nil ? (return nil) : (raise StandardError, "FIPS input must be 5 digit string")
      end

      state_code = FIPS::State.find_state_code(state_param: fips[0..1], return_nil: return_nil)
      return nil if state_code.nil?

      CSV.foreach(county_file(state_code: state_code)) do |county_row|
        # state_code (AL), state fips (01), county fips (001), name (Augtauga County), county gnis(00161526), class code (H1), status (A)
        return [county_row[3], state_code] if county_row[2] == fips[2..4]
      end

      raise StandardError, "Could not find county with fips: #{fips[2..4]}, in: #{state_code}" unless return_nil
    end

    def self.county_file(state_code:)
      file_path = "#{File.expand_path("..", __dir__)}/data/county/#{state_code}.csv"
      file_path if File.exist?(file_path)
    end

    def self.file(state_abbr)
      file_path = "#{File.expand_path("..", __dir__)}/data/county/#{state_abbr}.csv"
      file_path if File.exist?(file_path)
    end

    private

    def self.identify_with_fips(fips, state, county)
      return nil if fips.nil? || !fips.is_a?(String)

      case fips.length
      when 2
        return nil if county.nil?
        state_abbr = FIPS::State.state_abbr(fips)
        return by_name(state_abbr, county)
      when 3
        return nil if state.nil?
        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        return by_code(fips, state_abbr)
      when 5
        return by_code(fips, FIPS::State.state_abbr(fips[0, 2]))
      end
      return nil
    end

    def self.by_code(fips, state_abbr)      
      CSV.foreach(file(state_abbr)) do |county_row|
        county_fips = fips.length == 3 ? fips : fips[2, 3]
        return formatted_county(county_row) if county_row[2] == county_fips
      end
      raise StandardError, "Could not identify county with fips: #{fips}, in: #{state_abbr}"
    end

    def self.by_name(state_abbr, county)
      county_upcase = county.upcase

      CSV.foreach(file(state_abbr)) do |county_row|
        return formatted_county(county_row) if county_upcase == county_row[3].upcase
      end
      raise StandardError, "Could not identify county with name: #{county}, in: #{state_abbr}"
    end

    def self.county_lookup(state_code, county_param, return_nil, cache)
      upcase_param = county_param.upcase
      CSV.foreach(county_file(state_code: state_code)) do |row|
        return formatted_county(row) if match_county?(row, upcase_param)

        # keep? Memoize as file is being read but match isn't found ~ loses lookup flexiblity in county param + increases performacne?
        cache[[row[0], row[3].upcase]] = formatted_county(row) unless cache.key?([row[0], row[3].upcase])
      end
      return_nil ? (return {}) : (raise StandardError, "No county found matching: #{county_param}" unless return_nil)
    end

    def self.match_county?(row, param)
      row[3].upcase == param || row[4] == param || row[2] == param || "#{row[1]}#{row[2]}" == param
    end

    def self.formatted_county(row)
      # row => state (AL), state fips (01), county fips (001), name (Augtauga County), county gnis (00161526),  class code (H1), status (A)
      {
        state_abbr: row[0],
        fips: (row[1] + row[2]), # should combine these on txt file parsing (one fips not two for county)
        gnis: row[4],
        name: row[3],
        class_code: row[5],
        status: row[6]
      }
    end
  end
end
