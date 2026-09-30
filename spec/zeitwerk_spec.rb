# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Zeitwerk Autoloading" do
  it "eager loads this gem's namespace and classes" do
    lib_directory = File.expand_path("../lib", __dir__)
    loader = nil
    Zeitwerk::Registry.loaders.each do |candidate|
      loader = candidate if candidate.dirs.include?(lib_directory)
    end

    expect(loader).not_to be_nil, "No Zeitwerk loader found for #{lib_directory}"
    next unless loader

    expect { loader.eager_load }.not_to raise_error
    expect(FIPS::County).to be_a(Class)
    expect(FIPS::State).to be_a(Class)
    expect(FIPS::Subdivision).to be_a(Class)
  end
end
