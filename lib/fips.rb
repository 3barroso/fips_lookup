# frozen_string_literal: true

require "zeitwerk"

module FIPS
  loader = Zeitwerk::Loader.for_gem
  loader.inflector.inflect("fips" => "FIPS")
  loader.setup

  class NotFoundError < StandardError
  end

  class << self
    def lookup(**params)
      # params: fips, state, county, subdivision, (add gnis?, etc.)
      fips = params.fetch(:fips, nil)
      state = params.fetch(:state, nil)
      county = params.fetch(:county, nil)
      subdivision = params.fetch(:subdivision, nil)
      return identify_by_fips(fips, state, county, subdivision) unless fips.nil?

      return FIPS::State.lookup(state: state) if !state.nil? && county.nil? && subdivision.nil?
      return FIPS::County.lookup(state: state, county: county) if !state.nil? && !county.nil? && subdivision.nil?

      if !state.nil? && !county.nil? && !subdivision.nil?
        return FIPS::Subdivision.lookup(state: state, county: county,
                                        subdivision: subdivision)
      end

      raise ArgumentError, "Insufficient parameters to identify a state, county, or subdivision: #{params.inspect}"
    end

    private

    def identify_by_fips(fips, state, county, subdivision)
      raise ArgumentError, "FIPS input must be a string" unless fips.is_a?(String)

      case fips.length
      when 2
        return FIPS::Subdivision.lookup(fips: fips, county: county, subdivision: subdivision) if !county.nil? && !subdivision.nil?
        return FIPS::County.lookup(fips: fips, county: county) if !county.nil? && subdivision.nil?
        unless county.nil? && subdivision.nil?
          raise ArgumentError, "A 2-digit FIPS code requires both county and subdivision names for subdivision lookup"
        end

        FIPS::State.lookup(fips: fips)
      when 3
        return FIPS::Subdivision.lookup(fips: fips, state: state, subdivision: subdivision) if !state.nil? && !subdivision.nil?
        unless !state.nil? && county.nil? && subdivision.nil?
          raise ArgumentError, "A 3-digit FIPS code requires a state for county lookup, or state and subdivision for subdivision lookup"
        end

        FIPS::County.lookup(fips: fips, state: state)
      when 5
        return FIPS::Subdivision.lookup(fips: fips, subdivision: subdivision) unless subdivision.nil?
        return FIPS::Subdivision.lookup(fips: fips, state: state) if !state.nil? && county.nil?
        unless state.nil? && county.nil? && subdivision.nil?
          raise ArgumentError, "A 5-digit FIPS code accepts either state for subdivision FIPS or subdivision name for county FIPS"
        end

        FIPS::County.lookup(fips: fips)
      when 10
        FIPS::Subdivision.lookup(fips: fips)
      else
        raise ArgumentError, "FIPS code (#{fips}) must identify a state, county, or subdivision"
      end
    end
  end
end
