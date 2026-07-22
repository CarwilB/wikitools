# Fetch Plain Text of a Wikipedia Article

Fetches the rendered HTML of a Wikipedia article or historical revision
via the MediaWiki parse API, then strips all HTML tags to return clean
plain text. Unlike \[get_wikitext_by_name()\], this returns
human-readable prose rather than raw markup.

## Usage

``` r
get_plain_text(title = NULL, revision_id = NULL, lang = "en")
```

## Arguments

- title:

  Character. Wikipedia article title. Supply either \`title\` or
  \`revision_id\`, not both.

- revision_id:

  Numeric or character. Wikipedia revision ID. Supply either \`title\`
  or \`revision_id\`, not both.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A character string of plain text, or \`NULL\` if the article cannot be
retrieved or parsed.

## See also

\[get_wikitext_by_name()\], \[wikitext_to_plain()\]

## Examples

``` r
if (FALSE) { # \dontrun{
text <- get_plain_text("Bolivia")
cat(substr(text, 1, 500))

# Historical revision
text <- get_plain_text(revision_id = 1171236191)
} # }
```
