# FIPS Lookup

`fips_lookup` provides lookups for U.S. states, counties, and county subdivisions using Census FIPS identifiers and names. Results are hashes containing the fields for the requested geography. Lookup data is stored in a bundled SQLite database and queried read-only at runtime.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem "fips_lookup"
```

Then run `bundle install`.

## Usage

Require the gem if your application does not use Bundler's automatic loading:

```ruby
require "fips"
```

### General lookup

`FIPS.lookup` dispatches to the state, county, or subdivision lookup based on the supplied identifiers:

```ruby
FIPS.lookup(fips: "02")
# => { fips: "02", abbr: "AK", name: "Alaska", ansi: "01785533" }

FIPS.lookup(fips: "02060")
# => county record for Bristol Bay Borough

FIPS.lookup(fips: "0206009050")
# => subdivision record for Bristol Bay census subarea

FIPS.lookup(state: "Alaska", county: "Bristol Bay Borough")
# => county record for Bristol Bay Borough

FIPS.lookup(state: "Alaska", county: "Bristol Bay Borough",
            subdivision: "Bristol Bay census subarea")
# => subdivision record for Bristol Bay census subarea
```

FIPS codes must be strings so leading zeroes are preserved. The general dispatcher supports state FIPS (2 digits), county FIPS (5 digits), and full subdivision FIPS (10 digits). Contextual forms are also available through the specific lookup methods below.

### State lookup

```ruby
FIPS::State.lookup(fips: "02")
FIPS::State.lookup(state: "AK")
FIPS::State.lookup(state: "Alaska")
FIPS::State.lookup(state: "01785533") # ANSI code
```

The returned state hash has `:fips`, `:abbr`, `:name`, and `:ansi` keys. `FIPS::State.all` returns all state records in the same format:

```ruby
FIPS::State.all.map { |state| [state[:name], state[:abbr]] }
```

### County lookup

```ruby
FIPS::County.lookup(fips: "02060")
FIPS::County.lookup(fips: "060", state: "AK")
FIPS::County.lookup(fips: "02", county: "Bristol Bay Borough")
FIPS::County.lookup(state: "Alaska", county: "Bristol Bay Borough")
```

The returned county hash has `:state_abbr`, `:fips`, `:gnis`, `:name`, `:class_code`, and `:status` keys. State identifiers may be an abbreviation, name, FIPS code, or ANSI code.

To list counties in a state, use `FIPS::County.all`:

```ruby
counties = FIPS::County.all(state: "AK")
county_names = counties.map { |county| county[:name] }
```

### Subdivision lookup

```ruby
FIPS::Subdivision.lookup(fips: "0206009050")
FIPS::Subdivision.lookup(fips: "09050", state: "AK")
FIPS::Subdivision.lookup(fips: "02060", subdivision: "Bristol Bay census subarea")
FIPS::Subdivision.lookup(fips: "060", state: "AK",
                         subdivision: "Bristol Bay census subarea")
FIPS::Subdivision.lookup(state: "Alaska", county: "Bristol Bay Borough",
                         subdivision: "Bristol Bay census subarea")
```

The returned subdivision hash has `:state_abbr`, `:fips`, `:county_name`, `:gnis`, `:name`, `:class_code`, and `:status` keys. To retrieve subdivision records for a state, optionally filtered by county:

```ruby
FIPS::Subdivision.all(state: "AK")
FIPS::Subdivision.all(state: "AK", county: "Bristol Bay Borough")
```

County and subdivision name matching is case-insensitive. State identifiers accept abbreviations, names, FIPS codes, and ANSI codes.

### Source data

The raw and intermediate CSV datasets are retained under `source_data/` for rebuilding and auditing. They are development inputs, are not used at runtime, and are not included in the published gem. Runtime lookups and collection methods use the bundled SQLite database.

### Database build

The checked-in schema is in `db/schema.sql`. The bundled database is built from the 2020 Census county and county-subdivision source files. To rebuild it from the source text files and state data, run:

```sh
bundle exec ruby bin/db/build
```

The builder reads `source_data/state.csv`, `source_data/national_county2020.txt`, and `source_data/national_cousub2020.txt`, then writes `lib/data/fips.sqlite3`. The county and subdivision CSV snapshots under `source_data/county/` and `source_data/subdivision/` are retained for reference but are not used by the builder. An alternate output path can be supplied as the first argument. When updating the Census data vintage, replace the source files and rebuild the database. Only the generated SQLite file is packaged; source data is needed only when rebuilding or auditing it.

### Errors

Malformed or insufficient inputs raise `ArgumentError`. Validly formatted identifiers that do not match a record raise `FIPS::NotFoundError`, a subclass of `StandardError`:

```ruby
begin
  FIPS::County.lookup(fips: "02999")
rescue FIPS::NotFoundError => error
  warn error.message
end
```

## Development

Install dependencies with `bin/setup`. Run tests and lint with:

```sh
bundle exec rspec
bundle exec rubocop
```

Open an IRB console with `bin/console`. Install locally with `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome in the [FIPS repository](https://github.com/3barroso/fips_lookup). Contributors are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

This gem is available under the terms of the MIT License. See [LICENSE.txt](LICENSE.txt).