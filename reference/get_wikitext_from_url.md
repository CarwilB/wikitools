# Fetch Wikitext from a Wikipedia URL

Fetches wikitext from a Wikipedia article or historical revision URL.
Handles both standard article URLs (\`/wiki/Title\`) and revision links
(\`?title=Title&oldid=XXXXXXX\`), dispatching to
\[get_wikitext_by_name()\] or \[get_wikitext_by_revid()\] as
appropriate. The language is inferred from the subdomain (e.g.,
\`es.wikipedia.org\` as \`"es"\`).

## Usage

``` r
get_wikitext_from_url(url)
```

## Arguments

- url:

  Character. Full Wikipedia URL. Both current-article and \`?oldid=\`
  revision URLs are supported.

## Value

A character string of wikitext, or \`NULL\` if not retrievable.

## See also

\[get_wikitext_by_name()\], \[get_wikitext_by_revid()\]

## Examples

``` r
if (FALSE) { # \dontrun{
wt <- get_wikitext_from_url("https://en.wikipedia.org/wiki/La_Paz")

# Historical revision
wt <- get_wikitext_from_url(
  "https://en.wikipedia.org/w/index.php?title=La_Paz&oldid=1171236191"
)
} # }
```
