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
  limit = 5,
  .shortname = TRUE,
  .langname = FALSE
)
```

## Arguments

- df:

  A data frame or tibble containing the source names.

- name_col:

  Character. Name of the column containing search strings. Default
  \`"name"\`.

- lang:

  Character vector. One or more Wikipedia language codes (default
  \`"en"\`). When more than one code is supplied, each name is searched
  once per language and the results for every language are appended to
  the same output data frame, side by side. Supplying more than one
  language automatically forces \`.langname = TRUE\` (with a message) so
  the resulting columns don't collide.

- delay:

  Numeric. Seconds to pause between requests (default \`0.5\`). Set to
  \`0\` in tests or batch jobs where rate-limiting is handled elsewhere.
  The pause applies between consecutive requests within each language.

- limit:

  Integer. Maximum number of search results requested per query (default
  \`5\`). Only the top result is used.

- .shortname:

  Logical. If \`TRUE\` (default), output columns are prefixed \`wp\_\`
  (e.g. \`wp_found\`). If \`FALSE\`, columns are prefixed
  \`wikipedia\_\` (e.g. \`wikipedia_found\`).

- .langname:

  Logical. If \`TRUE\`, the language code is inserted into each column
  name (e.g. \`wp_en_found\` or \`wikipedia_en_found\`, depending on
  \`.shortname\`). Default \`FALSE\`. Useful when combining results from
  multiple language editions into the same data frame without
  collisions, and automatically enabled whenever \`lang\` has length
  greater than one.

## Value

The input data frame with five appended columns per language in
\`lang\`, named according to \`.shortname\` and \`.langname\`:

- found:

  Logical. \`TRUE\` if any search result was returned.

- match:

  Logical. \`TRUE\` if the top result title matches the query exactly
  (case- and whitespace-insensitive).

- title:

  Character. Title of the top search result, or \`NA\`.

- url:

  Character. Full Wikipedia URL of the top result, or \`NA\`.

- snippet:

  Character. HTML snippet from the search result, or \`NA\`.

## Details

A result is flagged as a match only when the top search title matches
the query exactly after stripping whitespace and lowercasing both
strings. This distinguishes an exact title match (e.g., searching
\`"Tracy K. Smith"\` and receiving \`"Tracy K. Smith"\`) from a related
result (e.g., receiving \`"Tracy K. Smith (poet)"\`).

## Examples

``` r
if (FALSE) { # \dontrun{
poets <- tibble::tibble(name = c("Tracy K. Smith", "Tishani Doshi"))
add_wikipedia_matches(poets)
add_wikipedia_matches(poets, .shortname = FALSE)
add_wikipedia_matches(poets, lang = "es", .langname = TRUE)

# Multiple languages in one call: results land in the same tibble,
# e.g. wp_en_found / wp_en_match and wp_cs_found / wp_cs_match
add_wikipedia_matches(poets, lang = c("en", "cs"))
} # }
```
