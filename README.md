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

### County info from lookup:  [.county(state_param: "state", county_name: "county name", _return_nil: false_)](/fips_lookup/lib/fips_lookup.rb?#L24)

Find County specific details using memoized hash state and county input. [ Returns state code, county fips, county name, and county class codes ]

Input the state name and county name and return the corresponding 5 digit FIPS code:
```
FipsLookup.county(state_param: "AL", county_name: "Autauga County") # => {:state_code=>"AL", :fips=>"01001", :name=>"Autauga County", :class_code=>"H1"}
```

* `state_param` - (String) flexible - able to find the state using its' 2 letter abbreviation ("AL"), 2 digit FIPS number ("01"), state name ("Alabama"), or the state ANSI code ("01779775").
* `county_name` - (String) must match spelling set by US Census Bureau, [resource library](https://www.census.gov/library/reference/code-lists/ansi.html)
— "Autauga County" can be found, "Autauga" can not be found.
* `return_nil` - (Boolean) is an optional parameter that when used overrides any Errors from input and returns an empty hash `{}`.
    * Ex:  `FipsLookup.county(state_param: "AL", county_name: "Autauga", return_nil: true) # => {}`

    * Ex: Access the [:fips] symbol after a lookup `FipsLookup.county(state_param: "AL", county_name: "Autauga", return_nil: true)[:fips] # => nil`

<br>

**How does it work?:**

Class attribute hash: [`@county_fips = { ["state_code", "county name"] => {:state_code, :fips, :name, :class_code} }`](/fips_lookup/lib/fips_lookup.rb?#L21)

The `county_fips` hash is built of key value pairs that grows as the `.county` method is used. Calls to `county` first searches `@county_fips` attribute with `[state_code, county_name]` before opening `.csv` files.  Therefore any duplicate calls made to `county` will return the value stored in `@county_fips`.  Instance variable lasts the lifespan of the FipsLookup class.
```
FipsLookup.county_fips # => { ["AL", "Autauga County"] => {:state_code=>"AL", :fips=>"01001", :name=>"Autauga County", :class_code=>"H1"} }
```

<hr>

### State / County lookup using FIPS code [.fips_county(fips: "fips", return_nil: _return_nil=false_)](/fips_lookup/lib/fips_lookup.rb?#L38)

Input the 5 digit FIPS code for a county and return the county name and state name in an Array:
```
FipsLookup.fips_county(fips: "01001") # => ["Autauga County", "AL"]
```

* `fips` - (String) must be a 5 character string of numbers ex: "01001".
* `return_nil` - (Boolean) is an optional parameter that when used overrides any Errors from input and returns `nil`.
    * Ex: `FipsLookup.fips_county(fips: "03000", return_nil: true) # => nil`

<br>

<hr>

### State info from lookup [.state(state_param: "state", _return_nil: false_)](/fips_lookup/lib/fips_lookup.rb?#L33)

Using state information input return a dictionary of values for keys fips, state code, state name, state ansi code.

```
FipsLookup.state(state_param: "01") # => {:fips=>"01", :code=>"AL", :name=>"Alabama", :ansi=>"01779775"}
```

* `state_param` - (String) flexible - able to find the state using its' 2 letter abbreviation ("AL"), 2 digit FIPS number ("01"), state name ("Alabama"), or the state ANSI code ("01779775").
* `return_nil` - (Boolean) is an optional parameter that when used overrides any Errors from input and returns an empty hash `{}`.

* `.state` functions similarly to the `.county` method in how it uses a memoized hash `@state_fips` to store state parameter lookups and return values before searching `state.csv` for more.

**State code lookup hash** [`STATE_CODES["state code"] # => "fips code"`](/fips_lookup/lib/fips_lookup.rb?#L8)
Can also be used for quick lookup translation between state 2-character abbreviations and state 2-digit FIPS code.
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
