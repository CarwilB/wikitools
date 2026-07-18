# Extract Numeric Multi-Claim Property Values

Internal helper that extracts value, year, and reference fields from all
claims for one quantity property in a Wikidata entity.

## Usage

``` r
.extract_numeric_list_property(entity, pid, pname, max_vals = 10)
```

## Arguments

- entity:

  A single Wikidata entity object.

- pid:

  Character. Property ID to extract (e.g., \`"P1082"\`).

- pname:

  Character. Output column prefix.

- max_vals:

  Integer. Maximum number of claim slots to emit.

## Value

A named list of scalar values suitable for row-binding.

## Details

Extract Numeric Multi-Claim Property Values
