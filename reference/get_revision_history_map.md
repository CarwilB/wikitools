# Fetch the Full Revision History of a Wikipedia Article

Returns a data frame of all revisions for a Wikipedia article, sorted
oldest to newest. Handles MediaWiki API pagination automatically, so
articles with thousands of revisions are fully retrieved.

## Usage

``` r
get_revision_history_map(article, lang = "en")
```

## Arguments

- article:

  Character. Wikipedia article title.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A data frame with columns \`revid\` (integer), \`timestamp\` (character,
ISO 8601), and \`user\` (character). Rows are sorted ascending by
timestamp.

## See also

\[find_sentence_insertion()\], \[track_wikipedia_sentences()\]

## Examples

``` r
if (FALSE) { # \dontrun{
map <- get_revision_history_map("Margaret Mead")
head(map)
} # }
```
