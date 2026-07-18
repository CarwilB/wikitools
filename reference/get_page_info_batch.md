# Fetch Page Metadata in Batches

Fetches basic metadata for a vector of Wikipedia page titles, batching
requests at 50 titles per API call. Useful for linking Wikipedia
articles to their Wikidata items or checking page sizes in bulk.

## Usage

``` r
get_page_info_batch(titles, lang = "en")
```

## Arguments

- titles:

  Character vector. Wikipedia page titles.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A tibble with one row per page and columns:

- title:

  Character. Normalized page title as returned by the API.

- pageid:

  Integer. MediaWiki page ID, or \`NA\` for missing pages.

- page_length:

  Integer. Page size in bytes, or \`NA\` for missing pages.

- wikidata_qid:

  Character. Linked Wikidata item QID (e.g., \`"Q2887"\`), or \`NA\` if
  none is set.

## See also

\[get_wp_category_members()\]

## Examples

``` r
if (FALSE) { # \dontrun{
titles <- c("La Paz", "Santa Cruz de la Sierra", "Cochabamba")
get_page_info_batch(titles, lang = "es")
} # }
```
