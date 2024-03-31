# frozen_string_literal: true

# County related section of FipsLookup module
module FipsLookup
  class << self
    def county(state_param:, county_param:, return_nil: false)
      state_code = find_state_code(state_param: state_param, return_nil: return_nil)
      return {} if state_code.nil?

      lookup = [state_code, county_param.upcase]
      @county_fips ||= {}
      @county_fips[lookup] ||= county_lookup(state_code, county_param, return_nil)
    end

    def fips_county(fips:, return_nil: false)
      unless fips.is_a?(String) && fips.length == 5
        return_nil ? (return nil) : (raise StandardError, "FIPS input must be 5 digit string")
      end

      state_code = find_state_code(state_param: fips[0..1], return_nil: return_nil)
      return nil if state_code.nil?

      CSV.foreach(county_file(state_code: state_code)) do |county_row|
        # state_code (AL), state fips (01), county fips (001), county gnis(00161526), name (Augtauga County), class code (H1), status (A)
        return [county_row[4], state_code] if county_row[2] == fips[2..4]
      end

      raise StandardError, "Could not find county with fips: #{fips[2..4]}, in: #{state_code}" unless return_nil
    end

    def county_file(state_code:)
      file_path = "#{File.expand_path("..", __dir__)}/data/county/#{state_code}.csv"
      file_path if File.exist?(file_path)
    end

    private

    def county_lookup(state_code, county_param, return_nil)
      upcase_param = county_param.upcase
      CSV.foreach(county_file(state_code: state_code)) do |county_row|
        return formatted_county(county_row) if match_county?(county_row, upcase_param)
      end
      return_nil ? (return {}) : (raise StandardError, "No county found matching: #{county_param}" unless return_nil)
    end

    def match_county?(row, param)
      # row => state (AL), state fips (01), county fips (001), county gnis (00161526), name (Augtauga County), class code (H1), status (A)
      row[4].upcase == param || row[3] == param || row[2] == param || "#{row[1]}#{row[2]}" == param
    end

    def formatted_county(row)
      {
        state_code: row[0],
        fips: (row[1] + row[2]),
        gnis: row[3],
        name: row[4],
        class_code: row[5],
        status: row[6]
      }
    end
  end
end
