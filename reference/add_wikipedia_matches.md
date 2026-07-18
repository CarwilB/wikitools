# Add Wikipedia Search Matches to a Data Frame

Searches Wikipedia for each value in a specified name column and appends
five match-metadata columns to the input data frame. Uses the MediaWiki
search API via \`httr\` and \`jsonlite\`.

## Usage

``` r
add_wikipedia_matches(
  df,
  name_col = "name",
  lang = "en",
  delay = 0.5,
  limit = 5
)
```

## Arguments

- df:

  A data frame or tibble containing the source names.

- name_col:

  Character. Name of the column containing search strings. Default
  \`"name"\`.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

- delay:

  Numeric. Seconds to pause between requests (default \`0.5\`). Set to
  \`0\` in tests or batch jobs where rate-limiting is handled elsewhere.

- limit:

  Integer. Maximum number of search results requested per query (default
  \`5\`). Only the top result is used.

## Value

The input data frame with five appended columns:

- wikipedia_found:

  Logical. \`TRUE\` if any search result was returned.

- wikipedia_match:

  Logical. \`TRUE\` if the top result title matches the query exactly
  (case- and whitespace-insensitive).

- wikipedia_title:

  Character. Title of the top search result, or \`NA\`.

- wikipedia_url:

  Character. Full Wikipedia URL of the top result, or \`NA\`.

- wikipedia_snippet:

  Character. HTML snippet from the search result, or \`NA\`.

## Details

A result is flagged as \`wikipedia_match = TRUE\` only when the top
search title matches the query exactly after stripping whitespace and
lowercasing both strings. This distinguishes an exact title match (e.g.,
searching \`"Tracy K. Smith"\` and receiving \`"Tracy K. Smith"\`) from
a related result (e.g., receiving \`"Tracy K. Smith (poet)"\`).

## Examples

``` r
if (FALSE) { # \dontrun{
poets <- tibble::tibble(name = c("Tracy K. Smith", "Tishani Doshi"))
add_wikipedia_matches(poets)
} # }
```
