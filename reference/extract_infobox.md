# Extract the First Infobox from Wikitext

Parses the first infobox template from raw wikitext into a named list of
field-value pairs. Uses brace-depth matching to correctly handle nested
templates within field values. Only the first infobox is extracted if
the article contains multiple. Field values are returned as-is (raw
wikitext); use \[clean_infobox_value()\] to strip markup.

## Usage

``` r
extract_infobox(wikitext)
```

## Arguments

- wikitext:

  Character. Raw wikitext string, as returned by
  \[get_wikitext_by_name()\] or \[cache_wikitext()\].

## Value

A named list where each element is a raw wikitext field value, or
\`NULL\` if no infobox is found or \`wikitext\` is \`NULL\`.

## Details

Recognises English (`Infobox`), Spanish (`Ficha de`), and Portuguese
(`Info/`) infobox conventions.

## See also

\[clean_infobox_value()\], \[get_wikitext_by_name()\]

## Examples

``` r
if (FALSE) { # \dontrun{
wt <- get_wikitext_by_name("La Paz")
box <- extract_infobox(wt)
clean_infobox_value(box[["population_total"]])
} # }
```
