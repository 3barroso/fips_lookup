# frozen_string_literal: true

# Subdivision related section of FipsLookup module
module FipsLookup
  class << self
    def subdivision(state_param:, subdivision_param:, return_nil: false)
      state_code = find_state_code(state_param: state_param, return_nil: return_nil)
      return {} if state_code.nil?

      lookup = [state_code, subdivision_param.upcase]
      @subdivision_fips ||= {}
      @subdivision_fips[lookup] ||= subdivision_lookup(state_code, subdivision_param, return_nil)
    end

    def subdivision_file(state_code:)
      file_path = "#{File.expand_path("..", __dir__)}/data/subdivision/#{state_code}.csv"
      file_path if File.exist?(file_path)
    end

    private

    def subdivision_lookup(state_code, subdivision_param, return_nil)
      upcase_param = subdivision_param.upcase
      CSV.foreach(subdivision_file(state_code: state_code)) do |subdivision_row|
        return formatted_subdivision(subdivision_row) if match_subdivision?(subdivision_row, upcase_param)
      end
      return_nil ? (return {}) : (raise StandardError, "No subdivision found matching: #{subdivision_param}" unless return_nil)
    end

    def match_subdivision?(row, param)
      # row => state_code (AL), state fips (01), county fips (001), county name (Augtauga County)
      #   row => subdivision name(Autaugaville CCD), class code (Z5), status (S)
      row[6].upcase == param || row[4] == param || row[5] == param
    end

    def formatted_subdivision(row)
      {
        state_code: row[0],
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
