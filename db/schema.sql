PRAGMA foreign_keys = ON;

CREATE TABLE states (
  state_fips TEXT PRIMARY KEY,
  state_abbr TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  name_key TEXT NOT NULL,
  ansi TEXT NOT NULL UNIQUE
);

CREATE INDEX states_name_key_idx ON states(name_key);

CREATE TABLE counties (
  state_fips TEXT NOT NULL,
  county_fips TEXT NOT NULL,
  full_fips TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  name_key TEXT NOT NULL,
  gnis TEXT NOT NULL,
  class_code TEXT NOT NULL,
  status TEXT NOT NULL,
  PRIMARY KEY (state_fips, county_fips),
  FOREIGN KEY (state_fips) REFERENCES states(state_fips)
);

CREATE INDEX counties_state_name_idx ON counties(state_fips, name_key);

CREATE TABLE subdivisions (
  full_fips TEXT PRIMARY KEY,
  state_fips TEXT NOT NULL,
  county_fips TEXT NOT NULL,
  subdivision_fips TEXT NOT NULL,
  name TEXT NOT NULL,
  name_key TEXT NOT NULL,
  gnis TEXT NOT NULL,
  class_code TEXT NOT NULL,
  status TEXT NOT NULL,
  UNIQUE (state_fips, county_fips, subdivision_fips),
  FOREIGN KEY (state_fips, county_fips) REFERENCES counties(state_fips, county_fips)
);

CREATE INDEX subdivisions_state_subdivision_fips_idx
  ON subdivisions(state_fips, subdivision_fips);
CREATE INDEX subdivisions_county_name_idx
  ON subdivisions(state_fips, county_fips, name_key);