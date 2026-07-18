# Search Wikipedia for One Query

Internal helper called row-wise by \[add_wikipedia_matches()\]. Uses the
MediaWiki search API via \`httr\` and \`jsonlite\`.

## Usage

``` r
search_wikipedia_one(query, lang = "en", limit = 5)
```

## Arguments

- query:

  Character. Search string.

- lang:

  Character. Wikipedia language code.

- limit:

  Integer. Maximum number of search results to request.

## Value

A named list with elements \`found\` (logical), \`title\`, \`url\`, and
\`snippet\` (all character). Returns \`found = FALSE\` with \`NA\`
fields when the query is blank, the search returns no results, or a
request error occurs.
