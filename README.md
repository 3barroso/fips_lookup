# FipsLookup

## Overview

FipsLookup is a gem that functions as a lookup used to identify county and state FIPS codes.

What are FIPS codes? The United States Federal Communications Commission (FCC) [says:](https://transition.fcc.gov/oet/info/maps/census/fips/fips.txt)

> Federal Information Processing System (FIPS) Codes for States and Counties
>
> FIPS codes are numbers which uniquely identify geographic areas.  The number of 
digits in FIPS codes vary depending on the level of geography.  State-level FIPS
codes have two digits, county-level FIPS codes have five digits of which the 
first two are the FIPS code of the state to which the county belongs.

_Note:_ FIPS codes are updated by the US census department they can be seen and accessed [here](https://www.census.gov/library/reference/code-lists/ansi.html).

<br>

**Interesting challenge:** <br>
Multiple states can have the same county name — 16 states have a "Wayne County". This means a state & county pair is required to lookup and return the proper FIPS code.
This gem utilizes memoization to increase lookup efficiency to csv files without adding complexity to your app.

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

### Find FIPS code by memoized hash with parameters: [.county("state name", "county name", _return_nil=false_)](/fips_lookup/lib/fips_lookup.rb?#L23)

Input the state name and county name and return the corresponding 5 digit FIPS code:
```
FipsLookup.county("AL", "Autauga County") # => "01001"
```

* `state name` - (String)  is flexible, preferring the state 2 letter abbreviation ("AL") or 2 digit FIPS code ("01"), but will also find the state by using state name ("Alabama"), or the state ANSI code ("01779775").
* `county name` - (String) is not flexible and must match spelling set by US Census Bureau, [resource library](https://www.census.gov/library/reference/code-lists/ansi.html)
— "Autauga County" can be found, "Autauga" can not be found.
* `return nil` - (Boolean) is an optional parameter that when used overrides any Errors from input and returns `nil`.
    * Ex:  `FipsLookup.county("AL", "Autauga", true) # => nil`

<br>

**Class attribute Hash:** [`county_fips = {["state name", "county name"] => "fips"}`](/fips_lookup/lib/fips_lookup.rb?#L21)

Hash built of key value pairs that grows as the `.county` method is used. Instance variable lasts the lifespan of the FipsLookup class.
```
FipsLookup.county_fips # => {["AL", "Autauga County"] => "01001"}
```

<hr>

### State / County lookup using FIPS code [.fips_county("fips", _return_nil=false_)](/fips_lookup/lib/fips_lookup.rb?#L57)

Input the 5 digit FIPS code for a county and return the county name and state name in an Array:
```
FipsLookup.fips_county("01001") # => ["Autauga County", "AL"]
```

* `fips` - (String) must be a 5 character string of numbers ex: "01001".
* `return_nil` - (Boolean) is an optional parameter that when used overrides any Errors from input and returns `nil`.
    * Ex: `FipsLookup.fips_county("03000", true) # => nil`

<br>

**State code lookup hash** [`STATE_CODES["state code"] # => "fips code"`](/fips_lookup/lib/fips_lookup.rb?#L8)
Can be used to translate between state 2-character abbreviations and state 2-digit FIPS code.
```
FipsLookup::STATE_CODES["AL"] #=> "01"
FipsLookup::STATE_CODES.key("01") # => "AL"
```


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
* [The first pull request](https://github.com/3barroso/fips_lookup/pull/1) contains more details to decisions and considerations when first launching gem.


## Contributing

Bug reports and pull requests are welcome on GitHub at the [FipsLookup repo](https://github.com/3barroso/fips_lookup).
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/3barroso/fips_lookup/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FipsLookup project's codebase, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/3barroso/fips_lookup/blob/main/CODE_OF_CONDUCT.md).
