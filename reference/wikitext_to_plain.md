# Convert Wikitext to Plain Text via Pandoc

Converts a raw wikitext string to clean plain text using Pandoc's
MediaWiki reader. Pandoc must be installed on the system; use
\`rmarkdown::pandoc_available()\` to check. Unlike
\[extract_clean_fragments()\], this preserves the full document
structure (headers, lists, tables) as plain prose rather than splitting
into sentence fragments.

## Usage

``` r
wikitext_to_plain(wikitext)
```

## Arguments

- wikitext:

  Character. Raw wikitext string, as returned by
  \[get_wikitext_by_name()\] or \[cache_wikitext()\].

## Value

A single character string of plain text.

## See also

\[get_plain_text()\], \[extract_clean_fragments()\]

## Examples

``` r
if (FALSE) { # \dontrun{
wt <- get_wikitext_by_name("Bolivia")
plain <- wikitext_to_plain(wt)
cat(substr(plain, 1, 500))
} # }
```
