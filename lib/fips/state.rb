# frozen_string_literal: true

# FIPS::State
module FIPS
  class State
    class << self
      def lookup(**params)
        fips = params.fetch(:fips, nil)
        state = params.fetch(:state, nil)

        unless fips.nil?
          raise ArgumentError, "FIPS input must be a 2 digit string" unless fips.is_a?(String) && fips.match?(/\A\d{2}\z/)

          return by_fips(fips)
        end

        unless state.nil?
          raise ArgumentError, "State input must be a non-empty string" unless state.is_a?(String) && !state.strip.empty?

          return by_name(state)
        end

        raise ArgumentError, "Could not identify state with parameters provided: #{params.inspect}"
      end

      def state_abbr(code)
        state = FIPS::Database.first(
          "SELECT state_abbr FROM states WHERE state_fips = ?",
          [code]
        )
        raise FIPS::NotFoundError, "No state found with code #{code}" if state.nil?

        state["state_abbr"]
      end

      def all
        FIPS::Database.all(
          "SELECT state_fips AS fips, state_abbr AS abbr, name, ansi FROM states ORDER BY state_fips"
        ).map { |state_row| formatted_state(state_row) }
      end

      private

      def by_fips(fips)
        state = FIPS::Database.first(
          "SELECT state_fips AS fips, state_abbr AS abbr, name, ansi FROM states WHERE state_fips = ?",
          [fips]
        )
        return formatted_state(state) unless state.nil?

        raise FIPS::NotFoundError, "No state found with fips #{fips}"
      end

      def by_name(state)
        state_upcase = state.upcase
        state_row = FIPS::Database.first(
          "SELECT state_fips AS fips, state_abbr AS abbr, name, ansi FROM states WHERE state_abbr = ? OR name_key = ? OR ansi = ? OR state_fips = ? LIMIT 1",
          [state_upcase, state_upcase, state, state]
        )
        return formatted_state(state_row) unless state_row.nil?

        raise FIPS::NotFoundError, "No state found matching: #{state}"
      end

      def formatted_state(row)
        {
          fips: row["fips"],
          abbr: row["abbr"],
          name: row["name"],
          ansi: row["ansi"]
        }
      end
    end
  end
end
