# Split Text on Top-Level Pipe Characters

Splits a string on \`\|\` characters that appear at the top nesting
level (i.e., outside \`{{ }}\` template and \`\[\[ \]\]\` link blocks).
Used internally to parse infobox fields without splitting on pipes
inside nested templates.

## Usage

``` r
split_on_top_level_pipes(text)
```

## Arguments

- text:

  Character string to split.

## Value

A character vector of segments.
