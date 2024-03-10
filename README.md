# FipsLookup

Welcome! This gem functions as a lookup that can be used to identify county and state FIPS codes. 

What are FIPS codes? The United States Federal Communications Commission (FCC) [says:](https://transition.fcc.gov/oet/info/maps/census/fips/fips.txt)

> Federal Information Processing System (FIPS) Codes for States and Counties
>
> FIPS codes are numbers which uniquely identify geographic areas.  The number of 
digits in FIPS codes vary depending on the level of geography.  State-level FIPS
codes have two digits, county-level FIPS codes have five digits of which the 
first two are the FIPS code of the state to which the county belongs.

FIPS codes are updated by the US census department and [accessed here](https://www.census.gov/library/reference/code-lists/ansi.html)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fips_lookup'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install fips_lookup

## Usage

To return the 5 digit FIPS code for the state / county:
```
# .county(string, string, boolean)
# FipsLookup.county(state_param, county_name_param, return_nil=false)
FipsLookup.county("AL", "Autauga County") => "01001"
```
_Note:_
* `state_param` variable is flexible, preferring the state 2 letter abbreviation or 2 digit FIPS code, but will also find the state by using state name, or the state ANSI code.

* `county_name_param` is not flexible and must match spelling (including "County").

* the `.county` method is a representation of the memoized hash class attribute `county_fips`. This means the `.county` method will return previously recorded look-ups before searching the county csv files.
<hr>

To return the county and state names using a 5 digit FIPS code:
```
# .fips_county(string, boolean)
# .fips_county(fips_param, return_nil=false)
FipsLookup.fips_county("01001") => ["Autauga County", "AL"]
```
_Note:_
* `fips_param` must be a 5 digit string ex: "01001"

### Error Handling:
All methods exposed in this gem have an optional boolean parameter `return_nil` that allow you to toggle if an error should be raised or if `nil` should be returned in case of a lookup error.

## Development

Download the repository locally, and from the directory run `bin/setup` to install gem dependencies.

Check installation and any changes by running `rspec` to run the tests. 

Use `bin/console` to open IRB console with FipsLookup gem included and ready to use.

To install this gem onto your local machine, run `bundle exec rake install`. 

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### New to Ruby?
On Mac, follow steps 1 and 2 of [this guide](https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-macos) to install ruby with rbenv using brew.

For PC, consult official ruby language [installation guides](https://www.ruby-lang.org/en/documentation/installation/).

#### New to this gem?

* The main working file is `lib/fips_lookup.rb` with usage examples in the test file: `spec/fips_lookup_spec.rb`
* [this pull request](https://github.com/3barroso/fips_lookup/pull/1) contains more details to decisions and considerations when first launching gem.


## Contributing

Bug reports and pull requests are welcome on GitHub at the [FipsLookup repo](https://github.com/3barroso/fips_lookup). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/3barroso/fips_lookup/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FipsLookup project's codebase, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/3barroso/fips_lookup/blob/main/CODE_OF_CONDUCT.md).
