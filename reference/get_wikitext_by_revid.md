# Fetch Raw Wikitext by Revision ID

Fetches raw wikitext for a specific historical revision of a Wikipedia
page. The revision ID uniquely identifies the content; the article title
is not required by the API and is ignored.

## Usage

``` r
get_wikitext_by_revid(article_name, revision_id, lang = "en")
```

## Arguments

- article_name:

  Character. Ignored. Accepted for interface consistency but not sent to
  the API – the revision ID alone identifies the content.

- revision_id:

  Character or numeric. Wikipedia revision ID, available from a page's
  "View history" tab or from the \`oldid\` query parameter in a
  Wikipedia URL.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A character string of wikitext, or \`NULL\` if the revision is not found
or the request fails.

## See also

\[get_wikitext_by_name()\], \[get_wikitext_from_url()\]

## Examples

``` r
if (FALSE) { # \dontrun{
wt <- get_wikitext_by_revid(NA, revision_id = 1171236191)
} # }
```
