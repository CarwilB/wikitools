# Find the Top Wikipedia Search Candidates for Each String

Searches Wikipedia for each string and returns the top \`n\` search hits
per string, rather than only the single top result as in
\[add_wikipedia_matches()\]. Useful when the correct article may not be
the first hit — for example, disambiguated titles like \`"Revolver
(Beatles album)"\` that rank below a more general page.

## Usage

``` r
find_wikipedia_matches(x, n = 6, name_col = "name", lang = "en", delay = 0.5)
```

## Arguments

- x:

  Character vector of search strings, or a data frame containing
  \`name_col\`.

- n:

  Integer. Number of search hits to return per string (default \`6\`).

- name_col:

  Character. When \`x\` is a data frame, the name of the column
  containing search strings. Ignored when \`x\` is a character vector.

- lang:

  Character. Wikipedia language code (default \`"en"\`). Unlike
  \[add_wikipedia_matches()\], only a single language is searched per
  call.

- delay:

  Numeric. Seconds to pause between requests (default \`0.5\`). Set to
  \`0\` in tests or batch jobs where rate-limiting is handled elsewhere.

## Value

A tibble with one row per search hit and columns:

- query:

  Character. The search string.

- rank:

  Integer. Position of the hit in the search results (1 = top).

- match:

  Logical. \`TRUE\` if this hit's title matches the query exactly (case-
  and whitespace-insensitive).

- title:

  Character. Article title of the hit.

- url:

  Character. Full Wikipedia URL of the hit.

- snippet:

  Character. HTML snippet from the search result.

Strings with no hits (or blank/\`NA\` strings) appear once with \`rank =
NA_integer\_\` and \`NA\` in the hit columns, so every input string is
represented in the output.

## Examples

``` r
if (FALSE) { # \dontrun{
find_wikipedia_matches(c("Revolver", "Let It Be"))
find_wikipedia_matches(c("Revolver", "Let It Be"), n = 3)

albums <- tibble::tibble(title = c("Revolver", "Abbey Road"))
find_wikipedia_matches(albums, name_col = "title")
} # }
```
