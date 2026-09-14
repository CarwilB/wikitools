# Search Wikidata for One Query

Internal helper called row-wise by \[add_wikidata_matches()\]. Uses the
\`wbsearchentities\` action of the Wikidata API via \`httr\` and
\`jsonlite\`. \`wbsearchentities\` matches only against entity
\*\*labels and aliases\*\* in the requested language – it does not
search description text.

## Usage

``` r
search_wikidata_one(query, lang = "en", limit = 5, type = "item")
```

## Arguments

- query:

  Character. Search string.

- lang:

  Character. Wikidata language code (used for both the \`language\` and
  \`uselang\` API parameters, so labels/aliases are matched and
  displayed in the same language).

- limit:

  Integer. Maximum number of search results to request.

- type:

  Character. Entity type to search (default \`"item"\`). Passed directly
  to the \`type\` parameter of \`wbsearchentities\` (e.g. \`"item"\`,
  \`"property"\`, \`"lexeme"\`).

## Value

A named list with elements \`found\` (logical), \`qid\`, \`label\`,
\`description\`, \`alias_match\` (logical, \`TRUE\` when the top hit
matched via an alias rather than the label), \`match_text\` (the label
or alias text the API matched against), and \`url\` (all character
except as noted). Returns \`found = FALSE\` with
\`NA\`/\`NA_character\_\` fields when the query is blank, the search
returns no results, or a request error occurs.
