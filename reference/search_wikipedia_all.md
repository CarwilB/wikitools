# Search Wikipedia and Return All Hits for One Query

Internal helper called row-wise by \[find_wikipedia_matches()\]. Uses
the MediaWiki search API via \`httr\` and \`jsonlite\`.

## Usage

``` r
search_wikipedia_all(query, lang = "en", limit = 6)
```

## Arguments

- query:

  Character. Search string.

- lang:

  Character. Wikipedia language code.

- limit:

  Integer. Maximum number of search results to request.

## Value

A tibble with columns \`title\`, \`url\`, and \`snippet\`, one row per
search hit (zero rows when the query is blank, the search returns no
results, or a request error occurs).
