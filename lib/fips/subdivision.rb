# frozen_string_literal: true

require "csv"

# FIPS::Subdivision
module FIPS
  class Subdivision
    class << self
      def lookup(**params)
        fips = params.fetch(:fips, nil)
        state = params.fetch(:state, nil)
        county = params.fetch(:county, nil)
        subdivision = params.fetch(:subdivision, nil)

        unless fips.nil? || (fips.is_a?(String) && fips.match?(/\A(?:\d{2}|\d{3}|\d{5}|\d{10})\z/))
          raise ArgumentError, "FIPS input must be a 2, 3, 5, or 10 digit string"
        end
        raise ArgumentError, "State input must be a non-empty string" unless state.nil? || (state.is_a?(String) && !state.strip.empty?)
        raise ArgumentError, "County input must be a non-empty string" unless county.nil? || (county.is_a?(String) && !county.strip.empty?)
        unless subdivision.nil? || (subdivision.is_a?(String) && !subdivision.strip.empty?)
          raise ArgumentError, "Subdivision input must be a non-empty string"
        end

        state_abbr = determine_state_abbr(fips, state)
        raise ArgumentError, "Could not determine state abbreviation from parameters provided: #{params.inspect}" if state_abbr.nil?

        location = identify_with_fips(fips, state, county, subdivision, state_abbr)
        return location unless location.nil?

        return by_name(state_abbr, county, subdivision) if %i[state county subdivision].all? { |key| !params[key].nil? }

        raise ArgumentError, "cannot determine subdivision: no valid parameters provided"
      end

      def all(state:, county: nil)
        raise ArgumentError, "State input must be a non-empty string" unless state.is_a?(String) && !state.strip.empty?
        raise ArgumentError, "County input must be a non-empty string" unless county.nil? || (county.is_a?(String) && !county.strip.empty?)

        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        raise ArgumentError, "Could not determine state abbreviation from state: #{state}" if state_abbr.nil?

        county_name = normalize_name(county)
        records = CSV.read(file_path(state_abbr))
        records.map do |row|
          formatted_subdivision(row)
        end.select { |record| county.nil? || normalize_name(record[:county_name]) == county_name }
      end

      def file_path(state_abbr)
        File.expand_path("../data/subdivision/#{state_abbr.upcase}.csv", __dir__)
      end

      private

      def determine_state_abbr(fips, state)
        return FIPS::State.lookup(state: state)[:abbr] unless state.nil?

        FIPS::State.fips_to_abbr(fips[0, 2]) unless fips.nil? || fips.length < 2
      end

      def identify_with_fips(fips, state, county, subdivision, state_abbr = nil)
        return nil if fips.nil?

        case fips.length
        when 2
          return nil if county.nil? || subdivision.nil?

          by_name(FIPS::State.fips_to_abbr(fips), county, subdivision)
        when 3
          return nil if state.nil? || subdivision.nil?

          state_abbr = FIPS::State.lookup(state: state)[:abbr]
          by_county_fips_and_sub_name(state_abbr, fips, subdivision)
        when 5
          unless subdivision.nil?
            state_abbr = FIPS::State.fips_to_abbr(fips[0, 2])
            return by_county_fips_and_sub_name(state_abbr, fips[2, 3], subdivision)
          end
          return nil if state.nil?

          state_abbr = FIPS::State.lookup(state: state)[:abbr]
          by_state_and_sub_fips(state_abbr, fips)
        when 10
          by_fips(fips)
        end
      end

      def by_state_and_sub_fips(state_abbr, fips)
        subdivision = state_index(state_abbr)[:by_subdivision_fips][fips]
        return subdivision unless subdivision.nil?

        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips}"
      end

      def by_fips(fips)
        state_abbr = FIPS::State.fips_to_abbr(fips[0, 2])
        subdivision = state_index(state_abbr)[:by_full_fips][fips]
        return subdivision unless subdivision.nil?

        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips}"
      end

      def by_name(state_abbr, county, subdivision)
        key = [normalize_name(county), normalize_name(subdivision)]
        match = state_index(state_abbr)[:by_county_and_name][key]
        return match unless match.nil?

        raise FIPS::NotFoundError, "No subdivision found matching: #{subdivision} in #{county}"
      end

      def by_county_fips_and_sub_name(state_abbr, county_fips, subdivision)
        key = [county_fips, normalize_name(subdivision)]
        match = state_index(state_abbr)[:by_county_fips_and_name][key]
        return match unless match.nil?

        nil
      end

      def state_index(state_abbr)
        indexes = subdivision_indexes
        indexes[state_abbr] ||= build_state_index(state_abbr)
      end

      def subdivision_indexes
        @subdivision_indexes ||= {}
      end

      def build_state_index(state_abbr)
        records = CSV.read(file_path(state_abbr)).map { |row| formatted_subdivision(row) }
        {
          records: records,
          by_full_fips: records.to_h { |record| [record[:fips], record] },
          by_subdivision_fips: records.each_with_object({}) do |record, index|
            subdivision_fips = record[:fips][5, 5]
            index[subdivision_fips] ||= record
          end,
          by_county_fips_and_name: records.to_h do |record|
            [[record[:fips][2, 3], normalize_name(record[:name])], record]
          end,
          by_county_and_name: records.to_h do |record|
            [[normalize_name(record[:county_name]), normalize_name(record[:name])], record]
          end
        }
      end

      def normalize_name(name)
        name.to_s.strip.downcase
      end

      def formatted_subdivision(row)
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
end
