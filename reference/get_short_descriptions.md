# Fetch Short Descriptions for Wikipedia Articles

Internal helper used by \[choose_wikipedia_matches()\]. Retrieves the
short description (the Wikidata-sourced subtitle shown under article
titles in the Wikipedia apps) for a set of article titles via the
MediaWiki \`prop=description\` API. Titles are batched into groups of 50
per request, the API maximum.

## Usage

``` r
get_short_descriptions(titles, lang = "en")
```

## Arguments

- titles:

  Character vector of Wikipedia article titles.

- lang:

  Character. Wikipedia language code.

## Value

A named character vector mapping title to short description. Titles with
no description map to \`NA_character\_\`.
