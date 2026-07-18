# Clean a Single Infobox Field Value

Strips wikitext and HTML markup from a raw infobox field value,
returning readable plain text. Handles: \`\<ref\>\` tags, arbitrary HTML
tags, wikilinks (keeping display text), \`{{flag}}\` / \`{{flagicon}}\`
/ \`{{flagcountry}}\` templates (keeping the country name),
\`{{convert}}\` templates (keeping value and unit), \`{{nowrap}}\`,
remaining \`{{ }}\` templates, and bare external links.

## Usage

``` r
clean_infobox_value(val)
```

## Arguments

- val:

  Character. Raw infobox field value, typically an element of the list
  returned by \[extract_infobox()\].

## Value

A cleaned character string, or \`NA_character\_\` if the input is
\`NULL\`, \`NA\`, or resolves to an empty string after cleaning.

## See also

\[extract_infobox()\]

## Examples

``` r
clean_infobox_value("[[Buenos Aires]]")        # "Buenos Aires"
#> [1] "Buenos Aires"
clean_infobox_value("{{flag|Bolivia}}")        # "Bolivia"
#> [1] "Bolivia"
clean_infobox_value("3,000<ref>Census</ref>")  # "3,000"
#> [1] "3,000"
clean_infobox_value(NA)                        # NA_character_
#> [1] NA
```
