# Format a Data Frame as a MediaWiki Wikitable

Converts a data frame to a MediaWiki wikitable string, ready to paste
into a Wikipedia article. Columns become headers; each row becomes a
table row. \`NA\` values are rendered as empty cells.

## Usage

``` r
as_wikitable(
  df,
  caption = NULL,
  class = "wikitable sortable",
  column_names = NULL
)
```

## Arguments

- df:

  A data frame.

- caption:

  Character. Optional table caption displayed above the table.

- class:

  Character. CSS class string applied to the table tag. Default
  \`"wikitable sortable"\` produces a bordered, user-sortable table.

- column_names:

  Character vector. Optional display names for columns. Must have the
  same length as \`ncol(df)\` if supplied. Defaults to the data frame's
  column names.

## Value

A single character string of wikitable markup.

## See also

\[get_wp_category_members()\]

## Examples

``` r
df <- data.frame(City = c("La Paz", "Santa Cruz"), Pop = c(835361, 1453549))
cat(as_wikitable(df, caption = "Bolivian cities"))
#> {| class="wikitable sortable"
#> |+ Bolivian cities
#> ! City !! Pop
#> |-
#> | La Paz ||  835361
#> |-
#> | Santa Cruz || 1453549
#> |}
```
