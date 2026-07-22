# Extract Citation References from Wikitext

Parses all \`Cite book\`, \`Cite journal\`, \`Cite web\`, and related
Wikipedia citation templates from raw wikitext into a tidy reference
tibble. Also captures bare \`\<ref\>\` notes that contain no citation
template.

## Usage

``` r
extract_refs_from_wikitext(wikitext)
```

## Arguments

- wikitext:

  Character. Raw wikitext string as returned by
  \[get_wikitext_by_name()\] or \[cache_wikitext()\].

## Value

A tibble with one row per citation found and columns: \`itemType\`,
\`title\`, \`creators\` (list-column of tibbles), \`date\`, \`year\`,
\`publisher\`, \`place\`, \`publicationTitle\`, \`volume\`, \`issue\`,
\`pages\`, \`ISBN\`, \`ISSN\`, \`DOI\`, \`url\`, \`language\`,
\`edition\`, \`series\`, \`accessDate\`, \`bookTitle\`, \`chapter\`,
\`first_author\`, \`.template_name\`, \`.raw_template\`. Issues a
warning and returns an empty tibble if no citation templates are found.

## Details

Recognised template families: Cite book, Cite journal, Cite web, Cite
news, Cite encyclopedia, Cite magazine, Cite thesis, Cite conference,
Cite report, Cite press release, Cite av media, Cite podcast, Cite
speech, Citation, Cite EB1911, and harvc.

## See also

\[get_wikitext_by_name()\], \[cache_wikitext()\]

## Examples

``` r
if (FALSE) { # \dontrun{
wt   <- get_wikitext_by_name("Meiō incident")
refs <- extract_refs_from_wikitext(wt)
dplyr::count(refs, itemType, sort = TRUE)
} # }
```
