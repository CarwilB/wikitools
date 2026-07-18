# Add a QuickStatements Column for Removing Statements to a Data Frame

Like `add_quick_statement_column` but negates the statement by
prepending a "-" to the command. This is useful for removing statements
via QuickStatements. Note that qualifiers and references cannot be used
with negated statements. The `property` argument must be a statement
property (e.g., `"P123"`).

## Usage

``` r
remove_quick_statement_column(dataframe, qid_col, property, value_col, ...)
```

## Arguments

- dataframe:

  A data frame (or tibble).

- qid_col:

  Unquoted column name containing Wikidata item IDs.

- property:

  Character. The property ID (e.g., `"P123"`).

- value_col:

  Unquoted column name containing statement values.

- ...:

  Additional arguments passed to \`create_quick_statement()\`.

## Value

The input data frame with an additional `quick_statement` column
containing negated statements.

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
  remove_quick_statement_column(qid, "P14142", cod.dep)
#> # A tibble: 10 × 4
#>    qid      label_en              cod.dep quick_statement              
#>    <chr>    <chr>                 <chr>   <chr>                        
#>  1 Q233169  Beni Department       08      "-Q233169 | P14142 | \"08\"" 
#>  2 Q233917  Cochabamba Department 03      "-Q233917 | P14142 | \"03\"" 
#>  3 Q233933  Tarija Department     06      "-Q233933 | P14142 | \"06\"" 
#>  4 Q235106  Santa Cruz Department 07      "-Q235106 | P14142 | \"07\"" 
#>  5 Q235110  Chuquisaca Department 01      "-Q235110 | P14142 | \"01\"" 
#>  6 Q235362  Pando Department      09      "-Q235362 | P14142 | \"09\"" 
#>  7 Q238079  Potosí Department     05      "-Q238079 | P14142 | \"05\"" 
#>  8 Q232784  La Paz Department     02      "-Q232784 | P14142 | \"02\"" 
#>  9 Q844510  Litoral               NA      "-Q844510 | P14142 | \"NA\"" 
#> 10 Q1061368 Oruro Department      04      "-Q1061368 | P14142 | \"04\""
```
