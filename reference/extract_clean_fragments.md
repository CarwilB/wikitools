# Extract Clean Text Fragments from Wikitext

Strips wikitext markup and splits the result into sentence-like
fragments. Removed markup includes: \`\<ref\>\` tags, templates (\`{{
}}\`), file/image links, section headers, and bold/italic formatting.
Wikilinks are either kept (display text only) or removed entirely
depending on \`keep_link_text\`. Fragments shorter than five words are
discarded.

## Usage

``` r
extract_clean_fragments(wikitext, keep_link_text = FALSE)
```

## Arguments

- wikitext:

  Character. Raw wikitext string.

- keep_link_text:

  Logical. If \`TRUE\`, retains the display text of
  \`\[\[Target\|Display\]\]\` wikilinks. If \`FALSE\` (default),
  wikilinks are removed entirely.

## Value

A character vector of unique cleaned text fragments, each containing at
least five words. Fragments are split on \`.\`, \`!\`, \`?\`, and
newlines.

## See also

\[get_wikitext_by_name()\], \[cache_wikitext()\]

## Examples

``` r
wt <- "La Paz is the [[seat of government]] of [[Bolivia]].
  It was founded in [[1548]].<ref>Smith 2000</ref>"
extract_clean_fragments(wt)
#> [1] "La Paz is the of"
extract_clean_fragments(wt, keep_link_text = TRUE)
#> [1] "La Paz is the seat of government of Bolivia"
#> [2] "It was founded in 1548"                     
```
