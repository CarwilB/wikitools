# Extract Census Years from Wikitext

Scans wikitext for common census year patterns and returns any
four-digit years found. Recognized patterns include
(case-insensitive): - \`YYYY census\` and \`YYYY \<word\> census\` -
\`census of YYYY\` - \`censo de YYYY\` (Spanish) - \`CPV YYYY\` (used in
Bolivian census references) - \`census_year = YYYY\` and
\`population_as_of = YYYY\` (infobox fields)

## Usage

``` r
extract_census_years(wikitext)
```

## Arguments

- wikitext:

  Character. Raw wikitext string.

## Value

A sorted character vector of unique four-digit year strings. Returns
\`character(0)\` if \`wikitext\` is \`NULL\` or no years are found.

## See also

\[extract_infobox()\], \[count_citations()\]

## Examples

``` r
wt <- "According to the 2001 census, and the 2012 census..."
extract_census_years(wt)  # c("2001", "2012")
#> [1] "2001" "2012"

wt2 <- "| population_as_of = 2024"
extract_census_years(wt2)  # "2024"
#> [1] "2024"
```
