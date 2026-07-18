# Count Reference Tags in Wikitext

Counts \`\<ref\>\` opening tags in wikitext, including self-closing tags
(\`\<ref name="x" /\>\`). Counts distinct inline references, not closing
\`\</ref\>\` tags. For citation template counts, see
\[count_citations()\].

## Usage

``` r
count_refs(wikitext)
```

## Arguments

- wikitext:

  Character. Raw wikitext string.

## Value

Integer. Number of \`\<ref\>\` tags found. Returns \`0L\` if
\`wikitext\` is \`NULL\`.

## See also

\[count_citations()\]

## Examples

``` r
wt <- "<ref>Smith 2000</ref> text <ref name='jones'/> more"
count_refs(wt)  # 2
#> [1] 3
```
