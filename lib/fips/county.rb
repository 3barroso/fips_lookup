# frozen_string_literal: true

require "csv"
require "pathname"

# FIPS::County
module FIPS
  class County

    class << self
      def lookup(**params)
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
          state_fips = FIPS::State.lookup(state: state)[:fips]
          return by_name(state_fips, county)
        end

        raise ArgumentError, "Could not identify county with parameters provided: #{params.inspect}"
      end

      def all(state:)
        raise ArgumentError, "State input must be a non-empty string" unless state.is_a?(String) && !state.strip.empty?

        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        rows = CSV.read(file_path(state_abbr))
        rows.map { |row| formatted_county(row) }
      end

      private

      def file_path(state)
        Pathname.getwd.join("lib/data/county/#{state.upcase}.csv")
      end

      def identify_with_fips(fips, state, county)
        return nil if fips.nil? || !fips.is_a?(String)

        case fips.length
        when 2
          return nil if county.nil?

          return by_name(fips, county)
        when 3
          return nil if state.nil?

          state_fips = FIPS::State.lookup(state: state)[:fips]
          return by_fips(state_fips + fips)
        when 5
          return by_fips(fips)
        end
        nil
      end

      def by_fips(fips)
        # county_row = db_first(
        #   "SELECT states.state_abbr AS state_abbr, counties.full_fips AS fips, counties.gnis, counties.name, counties.class_code, counties.status " \
        #   "FROM counties JOIN states USING (state_fips) WHERE counties.full_fips = ?",
        #   [fips]
        # )
        # return formatted_county(county_row) unless county_row.nil?

        raise FIPS::NotFoundError, "Could not identify county with fips: #{fips}"
      end

      def by_name(state_fips, county)
        # county_row = db_first(
        #   "SELECT states.state_abbr AS state_abbr, counties.full_fips AS fips, counties.gnis, counties.name, counties.class_code, counties.status " \
        #   "FROM counties JOIN states USING (state_fips) WHERE counties.state_fips = ? AND counties.name_key = ?",
        #   [state_fips, county.upcase]
        # )
        # return formatted_county(county_row) unless county_row.nil?

        raise FIPS::NotFoundError, "Could not identify county with name: #{county}, in: #{state_fips}"
      end

      def formatted_county(row)
        {
          state_abbr: row[0],
          fips: row[1] + row[2],
          gnis: row[4],
          name: row[3],
          class_code: row[5],
          status: row[6]
        }
      end
    end
  end
end
