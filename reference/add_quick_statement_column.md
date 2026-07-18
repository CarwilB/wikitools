# Add a QuickStatements Column to a Data Frame

A convenience wrapper around
[`create_quick_statement`](https://carwilb.github.io/wikitools/reference/create_quick_statement.md)
that adds a `quick_statement` column to a data frame by calling
[`create_quick_statement()`](https://carwilb.github.io/wikitools/reference/create_quick_statement.md)
row-wise via
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).

## Usage

``` r
add_quick_statement_column(dataframe, qid_col, property, value_col, ...)
```

## Arguments

- dataframe:

  A data frame (or tibble) to add the column to.

- qid_col:

  Unquoted column name containing Wikidata item IDs (e.g., `qid`).

- property:

  Character. The property ID (e.g., `"P31"`). Passed directly to
  [`create_quick_statement()`](https://carwilb.github.io/wikitools/reference/create_quick_statement.md).

- value_col:

  Unquoted column name containing the values to add.

- ...:

  Additional named arguments passed to
  [`create_quick_statement()`](https://carwilb.github.io/wikitools/reference/create_quick_statement.md)
  (e.g., `lang`, `type`, `reference_qid`, `reference_url`).

## Value

The input data frame with an additional `quick_statement` character
column.

## Examples

``` r
departments <- tibble::tribble(
~qid,             ~label_en, ~cod.dep,
"Q233169",     "Beni Department",     "08",
"Q233917", "Cochabamba Department",     "03",
"Q233933",   "Tarija Department",     "06",
"Q235106", "Santa Cruz Department",     "07",
"Q235110", "Chuquisaca Department",     "01",
"Q235362",    "Pando Department",     "09",
"Q238079",   "Potosí Department",     "05",
"Q232784",    "La Paz Department",     "02",
"Q844510",             "Litoral",       NA,
"Q1061368",    "Oruro Department",     "04"
)
departments %>%
  add_quick_statement_column(qid, "P14142", cod.dep,
                             reference_qid = "Q138354774")
#> # A tibble: 10 × 4
#>    qid      label_en              cod.dep quick_statement                       
#>    <chr>    <chr>                 <chr>   <chr>                                 
#>  1 Q233169  Beni Department       08      "Q233169 | P14142 | \"08\" | S248 | Q…
#>  2 Q233917  Cochabamba Department 03      "Q233917 | P14142 | \"03\" | S248 | Q…
#>  3 Q233933  Tarija Department     06      "Q233933 | P14142 | \"06\" | S248 | Q…
#>  4 Q235106  Santa Cruz Department 07      "Q235106 | P14142 | \"07\" | S248 | Q…
#>  5 Q235110  Chuquisaca Department 01      "Q235110 | P14142 | \"01\" | S248 | Q…
#>  6 Q235362  Pando Department      09      "Q235362 | P14142 | \"09\" | S248 | Q…
#>  7 Q238079  Potosí Department     05      "Q238079 | P14142 | \"05\" | S248 | Q…
#>  8 Q232784  La Paz Department     02      "Q232784 | P14142 | \"02\" | S248 | Q…
#>  9 Q844510  Litoral               NA      "Q844510 | P14142 | \"NA\" | S248 | Q…
#> 10 Q1061368 Oruro Department      04      "Q1061368 | P14142 | \"04\" | S248 | …
```
