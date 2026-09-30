# frozen_string_literal: true

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

        location = identify_with_fips(fips, state, county, subdivision)
        return location unless location.nil?

        return by_name(state, county, subdivision) if %i[state county subdivision].all? { |key| !params[key].nil? }

        raise ArgumentError, "cannot determine subdivision: no valid parameters provided"
      end

      def file(state_abbr)
        file_path = "#{File.expand_path("..", __dir__)}/data/subdivision/#{state_abbr}.csv"
        file_path if File.exist?(file_path)
      end

      private

      def identify_with_fips(fips, state, county, subdivision)
        return nil if fips.nil? || !fips.is_a?(String)

        valid_lengths = [2, 3, 5, 10]
        return nil unless valid_lengths.include?(fips.length)

        case fips.length
        when 2
          return nil if county.nil? || subdivision.nil?

          state_abbr = FIPS::State.state_abbr(fips)
          by_name(state_abbr, county, subdivision)
        when 3
          return nil if state.nil? || subdivision.nil?

          state_abbr = FIPS::State.lookup(state: state)[:abbr]
          by_county_fips_state_and_sub_name(fips, state_abbr, subdivision)
        when 5
          return by_fips_and_sub_name(fips, subdivision) unless subdivision.nil?
          return nil if state.nil?

          by_state_and_sub_fips(state, fips)
        when 10
          by_fips(fips)
        end
      end

      def by_state_and_sub_fips(state, fips)
        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        subdivision_file = file(state_abbr)
        CSV.foreach(subdivision_file) do |subdivision_row|
          return formatted_subdivision(subdivision_row) if subdivision_row[4] == fips
        end
        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips}"
      end

      def by_fips_and_sub_name(fips, subdivision)
        upcase_sub = subdivision.upcase
        state_abbr = FIPS::State.state_abbr(fips[0, 2])
        subdivision_file = file(state_abbr)
        CSV.foreach(subdivision_file) do |subdivision_row|
          return formatted_subdivision(subdivision_row) if subdivision_row[2] == fips[2, 3] && subdivision_row[6].upcase == upcase_sub
        end
        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips} and name: #{subdivision}"
      end

      def by_county_fips_state_and_sub_name(fips, state_abbr, subdivision)
        sub_upcase = subdivision.upcase
        CSV.foreach(file(state_abbr)) do |subdivision_row|
          return formatted_subdivision(subdivision_row) if subdivision_row[2] == fips && subdivision_row[6].upcase == sub_upcase
        end
        raise FIPS::NotFoundError, "No subdivision found matching county fips: #{fips}, state: #{state_abbr}, and name: #{subdivision}"
      end

      def by_fips(fips)
        state_code = fips[0, 2]
        state_abbr = FIPS::State.state_abbr(state_code)

        subdivision_file = file(state_abbr)
        CSV.foreach(subdivision_file) do |subdivision_row|
          return formatted_subdivision(subdivision_row) if subdivision_row[1] + subdivision_row[2] + subdivision_row[4] == fips
        end
        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips}"
      end

      def by_name(state, county, subdivision)
        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        sub_upcase = subdivision.upcase
        county_upcase = county.upcase

        subdivision_file = file(state_abbr)
        CSV.foreach(subdivision_file) do |subdivision_row|
          if subdivision_row[3].upcase == county_upcase && subdivision_row[6].upcase == sub_upcase
            return formatted_subdivision(subdivision_row)
          end
        end
        raise FIPS::NotFoundError, "No subdivision found matching: #{subdivision} in #{county}"
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
