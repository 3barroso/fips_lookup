# frozen_string_literal: true

require "csv"

# FIPS::County
module FIPS
  class County
    class << self
      def county_cache
        @county_cache ||= {}
      end

      def loaded_states
        @loaded_states ||= {}
      end

      def lookup(**params)
        fips = params.fetch(:fips, nil)
        state = params.fetch(:state, nil)
        county = params.fetch(:county, nil)

        unless fips.nil? || (fips.is_a?(String) && fips.match?(/\A(?:\d{2}|\d{3}|\d{5})\z/))
          raise ArgumentError, "FIPS input must be a 2, 3, or 5 digit string"
        end
        raise ArgumentError, "State input must be a non-empty string" unless state.nil? || (state.is_a?(String) && !state.strip.empty?)
        raise ArgumentError, "County input must be a non-empty string" unless county.nil? || (county.is_a?(String) && !county.strip.empty?)
        raise ArgumentError, "Lookup requires at least one of fips, state, or county parameters" if fips.nil? && state.nil? && county.nil?

        state_abbr = determine_state_abbr(fips, state)
        raise ArgumentError, "Could not determine state abbreviation from parameters provided: #{params.inspect}" if state_abbr.nil?

        ensure_csv_indexed!(state_abbr)

        if county
          cache_key = "#{state_abbr}:#{county.to_s.strip.downcase}"
          match = county_cache[cache_key]
          return match if match
        end

        if fips
          case fips.length
          when 3
            full_fips = FIPS::State.abbr_to_fips(state_abbr) + fips
            cache_key = "#{state_abbr}:#{full_fips.to_s.strip}"
          when 5
            cache_key = "#{state_abbr}:#{fips.to_s.strip}"
          end
          match = county_cache[cache_key]
          return match if match
        end
        raise ArgumentError, "Could not identify county with parameters provided: #{params.inspect}"
      end

      def all(state:)
        raise ArgumentError, "State input must be a non-empty string" unless state.is_a?(String) && !state.strip.empty?

        state_abbr = FIPS::State.lookup(state: state)[:abbr]
        rows = CSV.read(file_path(state_abbr))
        rows.map { |row| formatted_county(row) }
      end

      def file_path(state_abbr)
        File.expand_path("../data/county/#{state_abbr.upcase}.csv", __dir__)
      end

      private

      def determine_state_abbr(fips, state)
        case fips&.length
        when 2
          FIPS::State.fips_to_abbr(fips)
        when 3
          raise ArgumentError, "A 3-digit FIPS code requires a state for county lookup" if state.nil?

          FIPS::State.lookup(state: state)[:abbr]
        when 5
          FIPS::State.fips_to_abbr(fips[0..1])
        else
          raise ArgumentError, "State input is required to lookup county information" if state.nil?

          FIPS::State.lookup(state: state)[:abbr]
        end
      end

      def ensure_csv_indexed!(state_abbr)
        return if loaded_states[state_abbr]

        raw_content = CSV.read(file_path(state_abbr))
        raw_content.each do |row|
          row_hash = formatted_county(row)

          name_key = "#{state_abbr}:#{row_hash[:name].to_s.strip.downcase}"
          county_cache[name_key] = row_hash
          fips_key = "#{state_abbr}:#{row_hash[:fips].to_s.strip}"
          county_cache[fips_key] = row_hash
        end
        loaded_states[state_abbr] = true
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
