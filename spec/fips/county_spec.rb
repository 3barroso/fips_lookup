# spec/fips/county_spec.rb
require "spec_helper"

RSpec.describe FIPS::County do

  it "tests the check method" do
    expect(FIPS::County.rename_check).to eq("inside rename check for FIPS::County")
  end
end
