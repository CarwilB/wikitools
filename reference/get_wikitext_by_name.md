# Fetch Raw Wikitext by Article Name

Fetches the raw wikitext of the current revision of a Wikipedia article
via the MediaWiki API.

## Usage

``` r
get_wikitext_by_name(article_name, lang = "en")
```

## Arguments

- article_name:

  Character. Wikipedia article title, as it appears in the page URL
  (spaces are handled; capitalization matters).

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A character string of wikitext, or \`NULL\` if the article is not found
or the request fails.

## See also

\[get_wikitext_by_revid()\], \[get_wikitext_from_url()\],
\[cache_wikitext()\]

## Examples

``` r
if (FALSE) { # \dontrun{
wt <- get_wikitext_by_name("Bogot\u00E1")
substr(wt, 1, 200)
} # }
```
