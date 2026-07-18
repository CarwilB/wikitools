# Count Citation Templates in Wikitext

Counts occurrences of \`{{cite ...}}\` and \`{{Citation ...}}\`
templates. Note that bare \`\<ref\>\` tags without a citation template
(e.g., named references or bare URLs) are not counted here; see
\[count_refs()\] for those.

## Usage

``` r
count_citations(wikitext)
```

## Arguments

- wikitext:

  Character. Raw wikitext string.

## Value

Integer. Number of citation templates found. Returns \`0L\` if
\`wikitext\` is \`NULL\`.

## See also

\[count_refs()\]

## Examples

``` r
wt <- "Text.\\{\\{cite book|author=Smith|year=2000\\}\\}
  More text.\\{\\{Citation|author=Jones\\}\\}<ref name='x'/>"
count_citations(wt)  # 2
#> [1] 0
count_refs(wt)       # 2
#> [1] 2
```
