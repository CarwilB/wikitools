# Interactively Choose Wikipedia Articles from Search Candidates

For each search string, shows the top \`n\` Wikipedia search hits (from
\[find_wikipedia_matches()\]) together with each article's short
description in an interactive \[utils::menu()\], and records the article
the user selects. Intended for cases where the top search hit is not
reliably the intended article — for example, album titles that also name
a film or song.

## Usage

``` r
choose_wikipedia_matches(x, n = 6, name_col = "name", lang = "en", delay = 0.5)
```

## Arguments

- x:

  Character vector of search strings, or a data frame containing
  \`name_col\`.

- n:

  Integer. Number of search hits shown per string (default \`6\`).

- name_col:

  Character. When \`x\` is a data frame, the name of the column
  containing search strings. Ignored when \`x\` is a character vector.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

- delay:

  Numeric. Seconds to pause between search requests (default \`0.5\`).
  Set to \`0\` when rate-limiting is handled elsewhere.

## Value

A tibble with one row per search string and columns:

- query:

  Character. The search string.

- found:

  Logical. \`TRUE\` if any search hits were returned.

- chosen:

  Logical. \`TRUE\` if the user selected a hit; \`FALSE\` if the user
  chose "None of these" or no hits were available.

- rank:

  Integer. Rank of the chosen hit in the search results, or \`NA\`.

- title:

  Character. Title of the chosen article, or \`NA\`.

- url:

  Character. Full Wikipedia URL of the chosen article, or \`NA\`.

- description:

  Character. Short description of the chosen article, or \`NA\`.

## Examples

``` r
if (FALSE) { # \dontrun{
choose_wikipedia_matches(c("Revolver", "Let It Be"))

albums <- tibble::tibble(title = c("Revolver", "Abbey Road"))
choices <- choose_wikipedia_matches(albums, name_col = "title")
} # }
```
