# frozen_string_literal: true

# FIPS::County
module FIPS
  class County
    def self.lookup(**params)
      fips = params.fetch(:fips, nil)
      state = params.fetch(:state, nil)
      county = params.fetch(:county, nil)

      unless fips.nil? || (fips.is_a?(String) && fips.match?(/\A(?:\d{2}|\d{3}|\d{5})\z/))
        raise ArgumentError, "FIPS input must be a 2, 3, or 5 digit string"
      end
      raise ArgumentError, "State input must be a non-empty string" unless state.nil? || (state.is_a?(String) && !state.strip.empty?)
      raise ArgumentError, "County input must be a non-empty string" unless county.nil? || (county.is_a?(String) && !county.strip.empty?)

      location = identify_with_fips(fips, state, county)
      return location unless location.nil?

      if !county.nil? && !state.nil?
        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        return by_name(state_abbr, county)
      end

      raise ArgumentError, "Could not identify county with parameters provided: #{params.inspect}"
    end

    def self.file(state_abbr)
      file_path = "#{File.expand_path("..", __dir__)}/data/county/#{state_abbr}.csv"
      file_path if File.exist?(file_path)
    end

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
      nil
    end

    def self.by_code(fips, state_abbr)
      CSV.foreach(file(state_abbr)) do |county_row|
        county_fips = fips.length == 3 ? fips : fips[2, 3]
        return formatted_county(county_row) if county_row[2] == county_fips
      end
      raise FIPS::NotFoundError, "Could not identify county with fips: #{fips}, in: #{state_abbr}"
    end

    def self.by_name(state_abbr, county)
      county_upcase = county.upcase

      CSV.foreach(file(state_abbr)) do |county_row|
        return formatted_county(county_row) if county_upcase == county_row[3].upcase
      end
      raise FIPS::NotFoundError, "Could not identify county with name: #{county}, in: #{state_abbr}"
    end

    def self.formatted_county(row)
      # row => state (AL), state fips (01), county fips (001), name (Augtauga County), county gnis (00161526),  class code (H1), status (A)
      {
        state_abbr: row[0],
        fips: (row[1] + row[2]),
        gnis: row[4],
        name: row[3],
        class_code: row[5],
        status: row[6]
      }
    end
  end
end
