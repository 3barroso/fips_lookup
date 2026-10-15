# FIPS Lookup

`fips_lookup` is a ruby gem that functions as a lookup for U.S. states, counties, and county subdivisions using Census FIPS identifiers and names. 

Lookup results are hashes containing the fields for the requested geography. Lookup data is stored in a bundled SQLite database and queried read-only at runtime.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem "fips_lookup"
```
Then run `bundle install`

### What version is right for you?

fips_lookup >= 1.0 - SQLite database, with indexed lookups, zeitwerk, lightning fast lookups, more infrastructure required to run SQLite

fips lookup < 1.0 - CSV memoization and indexed lookup, lightweight, zeitwerk compatible, 

## Usage

Require the gem if your application does not use Bundler's automatic loading:

```ruby
require "fips"
```

### Examples in Gist

Check out this RunRuby.dev gist of examples of how to use the gem, and what parameters are available
[FIPS examples](https://runruby.dev/?gist=864b1b4aa26014684c95465a7159d453)



### Source data

The raw and intermediate CSV datasets are retained under `source_data/` for rebuilding and auditing. They are development inputs, are not used at runtime, and are not included in the published gem. Runtime lookups and collection methods use the bundled SQLite database.

### Database build

The checked-in schema is in `db/schema.sql`. The bundled database is built from the 2020 Census county and county-subdivision source files. To rebuild it from the source text files and state data, run:

```sh
bundle exec ruby bin/db/build
```

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