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

        if %i[state county subdivision].all? { |key| !params[key].nil? }
          state_fips = FIPS::State.lookup(state: state)[:fips]
          return by_name(state_fips, county, subdivision)
        end

        raise ArgumentError, "cannot determine subdivision: no valid parameters provided"
      end

      def all(state:, county: nil)
        unless state.is_a?(String) && !state.strip.empty?
          raise ArgumentError, "State input must be a non-empty string"
        end
        unless county.nil? || (county.is_a?(String) && !county.strip.empty?)
          raise ArgumentError, "County input must be a non-empty string"
        end

        state_fips = FIPS::State.lookup(state: state)[:fips]
        where_clause = "subdivisions.state_fips = ?"
        bind_vars = [state_fips]
        unless county.nil?
          where_clause += " AND counties.name_key = ?"
          bind_vars << county.upcase
        end
        select_subdivisions(where_clause, bind_vars)
      end

      private

      def identify_with_fips(fips, state, county, subdivision)
        return nil if fips.nil? || !fips.is_a?(String)

        valid_lengths = [2, 3, 5, 10]
        return nil unless valid_lengths.include?(fips.length)

        case fips.length
        when 2
          return nil if county.nil? || subdivision.nil?

          by_name(fips, county, subdivision)
        when 3
          return nil if state.nil? || subdivision.nil?

          state_fips = FIPS::State.lookup(state: state)[:fips]
          by_county_fips_state_and_sub_name(fips, state_fips, subdivision)
        when 5
          return by_fips_and_sub_name(fips, subdivision) unless subdivision.nil?
          return nil if state.nil?

          by_state_and_sub_fips(state, fips)
        when 10
          by_fips(fips)
        end
      end

      def by_state_and_sub_fips(state, fips)
        state_fips = FIPS::State.lookup(state: state)[:fips]
        subdivision_row = select_subdivision(
          "subdivisions.state_fips = ? AND subdivisions.subdivision_fips = ?",
          [state_fips, fips]
        )
        return subdivision_row unless subdivision_row.nil?

        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips}"
      end

      def by_fips_and_sub_name(fips, subdivision)
        FIPS::State.lookup(fips: fips[0, 2])
        subdivision_row = select_subdivision(
          "subdivisions.state_fips = ? AND subdivisions.county_fips = ? AND subdivisions.name_key = ?",
          [fips[0, 2], fips[2, 3], subdivision.upcase]
        )
        return subdivision_row unless subdivision_row.nil?

        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips} and name: #{subdivision}"
      end

      def by_county_fips_state_and_sub_name(fips, state_fips, subdivision)
        subdivision_row = select_subdivision(
          "subdivisions.state_fips = ? AND subdivisions.county_fips = ? AND subdivisions.name_key = ?",
          [state_fips, fips, subdivision.upcase]
        )
        return subdivision_row unless subdivision_row.nil?

        raise FIPS::NotFoundError, "No subdivision found matching county fips: #{fips}, state: #{state_fips}, and name: #{subdivision}"
      end

      def by_fips(fips)
        FIPS::State.lookup(fips: fips[0, 2])
        subdivision_row = select_subdivision("subdivisions.full_fips = ?", [fips])
        return subdivision_row unless subdivision_row.nil?

        raise FIPS::NotFoundError, "No subdivision found matching fips: #{fips}"
      end

      def by_name(state_fips, county, subdivision)
        county_row = FIPS::Database.first(
          "SELECT county_fips FROM counties WHERE state_fips = ? AND name_key = ?",
          [state_fips, county.upcase]
        )
        unless county_row.nil?
          subdivision_row = select_subdivision(
            "subdivisions.state_fips = ? AND subdivisions.county_fips = ? AND subdivisions.name_key = ?",
            [state_fips, county_row["county_fips"], subdivision.upcase]
          )
          return subdivision_row unless subdivision_row.nil?
        end

        raise FIPS::NotFoundError, "No subdivision found matching: #{subdivision} in #{county}"
      end

      def select_subdivision(where_clause, bind_vars)
        select_subdivisions(where_clause, bind_vars).first
      end

      def select_subdivisions(where_clause, bind_vars)
        rows = FIPS::Database.all(
          "SELECT states.state_abbr AS state_abbr, subdivisions.full_fips AS fips, counties.name AS county_name, " \
          "subdivisions.gnis AS gnis, subdivisions.name AS name, subdivisions.class_code AS class_code, subdivisions.status AS status " \
          "FROM subdivisions JOIN states USING (state_fips) JOIN counties USING (state_fips, county_fips) " \
          "WHERE #{where_clause} ORDER BY subdivisions.full_fips",
          bind_vars
        )
        rows.map { |row| formatted_subdivision(row) }
      end

      def formatted_subdivision(row)
        return nil if row.nil?

        {
          state_abbr: row["state_abbr"],
          fips: row["fips"],
          county_name: row["county_name"],
          gnis: row["gnis"],
          name: row["name"],
          class_code: row["class_code"],
          status: row["status"]
        }
      end
    end
  end
end
