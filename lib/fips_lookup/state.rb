# frozen_string_literal: true

# State related section of FipsLookup module
module FipsLookup
  class << self
    def state(state_param:, return_nil: false)
      @state_fips ||= {}
      @state_fips[state_param] ||= state_lookup(state_param, return_nil)
    end

    def find_state_code(state_param:, return_nil: false)
      return state_param.upcase if STATE_CODES.key?(state_param.upcase)
      return STATE_CODES.key(state_param) if STATE_CODES.value?(state_param)

      state(state_param: state_param, return_nil: return_nil)[:code]
    end

    def state_file
      "#{File.expand_path("..", __dir__)}/data/state.csv"
    end

    private

    def state_lookup(state_param, return_nil = false)
      upstate_param = state_param.upcase
      CSV.foreach(state_file) do |state_row|
        return formatted_state(state_row) if state_match_row?(state_row, upstate_param)
      end
      return_nil ? (return {}) : (raise StandardError, "No state found matching: #{state_param}")
    end

    def state_match_row?(row, param)
      # row => state fips (01), state code (AL), state name (Alabama), ansi (01779775)
      row[0] == param || row[1] == param || row[2].upcase == param || row[3] == param
    end

    def formatted_state(row)
      {
        fips: row[0],
        code: row[1],
        name: row[2],
        ansi: row[3]
      }
    end
  end
end
