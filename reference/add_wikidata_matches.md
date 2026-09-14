# Add Wikidata Search Matches to a Data Frame

Searches Wikidata for each value in a specified name column and appends
match-metadata columns to the input data frame. Uses the
\`wbsearchentities\` action of the Wikidata API via \`httr\` and
\`jsonlite\`.

## Usage

``` r
add_wikidata_matches(
  df,
  name_col = "name",
  lang = "en",
  delay = 0.5,
  limit = 5,
  type = "item",
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

  Character vector. One or more Wikidata language codes (default
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

- type:

  Character. Wikidata entity type to search (default \`"item"\`).
  Forwarded to \[search_wikidata_one()\].

- .shortname:

  Logical. If \`TRUE\` (default), output columns are prefixed \`wd\_\`
  (e.g. \`wd_found\`). If \`FALSE\`, columns are prefixed \`wikidata\_\`
  (e.g. \`wikidata_found\`).

- .langname:

  Logical. If \`TRUE\`, the language code is inserted into each column
  name (e.g. \`wd_en_found\` or \`wikidata_en_found\`, depending on
  \`.shortname\`). Default \`FALSE\`. Useful when combining results from
  multiple languages into the same data frame without collisions, and
  automatically enabled whenever \`lang\` has length greater than one.

## Value

The input data frame with seven appended columns per language in
\`lang\`, named according to \`.shortname\` and \`.langname\`:

- found:

  Logical. \`TRUE\` if any search result was returned.

- match:

  Logical. \`TRUE\` if the top hit's matched label/alias text equals the
  query exactly (case- and whitespace-insensitive).

- qid:

  Character. Wikidata item ID of the top hit, or \`NA\`.

- label:

  Character. Label of the top hit in \`lang\`, or \`NA\`.

- description:

  Character. Description of the top hit in \`lang\`, or \`NA\`.
  Informational only – not used to determine \`match\`.

- alias_match:

  Logical. \`TRUE\` if the top hit matched via an alias rather than the
  label, \`NA\` if no hit was found.

- url:

  Character. Full Wikidata URL of the top hit, or \`NA\`.

## Details

Matching searches \*\*labels and aliases only\*\*, in the language given
by \`lang\` – description text is never searched. This mirrors how
\`wbsearchentities\` itself works: it returns, for each hit, which field
(\`label\` or \`alias\`) the query matched and the exact matched text. A
result is flagged as a match only when that matched text equals the
query exactly, after stripping whitespace and lowercasing both strings –
the same convention used by \[add_wikipedia_matches()\]. The entity's
description is included in the output for context only; it does not
affect whether a row counts as a match.

## See also

\[add_wikipedia_matches()\]

## Examples

``` r
if (FALSE) { # \dontrun{
poets <- tibble::tibble(name = c("Tracy K. Smith", "Tishani Doshi"))
add_wikidata_matches(poets)
add_wikidata_matches(poets, .shortname = FALSE)
add_wikidata_matches(poets, lang = "es", .langname = TRUE)

# Multiple languages in one call: results land in the same tibble,
# e.g. wd_en_found / wd_en_match and wd_cs_found / wd_cs_match
add_wikidata_matches(poets, lang = c("en", "cs"))
} # }
```
