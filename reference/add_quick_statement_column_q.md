# Add a QuickStatements Column with Qualifiers to a Data Frame

Like `add_quick_statement_column` but exposes the `qualifiers` argument
so that each statement can carry qualifier triples. Qualifier properties
are given as `"P123"` and are automatically converted to the
QuickStatements `qalXXX` token format required by the API.

## Usage

``` r
add_quick_statement_column_q(
  dataframe,
  qid_col,
  property,
  value_col,
  qualifiers = NULL,
  ...
)
```

## Arguments

- dataframe:

  A data frame (or tibble).

- qid_col:

  Unquoted column name containing Wikidata item IDs.

- property:

  Character. The property ID (e.g., `"P1098"`).

- value_col:

  Unquoted column name containing statement values.

- qualifiers:

  Named list of qualifier property → value pairs. Names must be property
  IDs in format `"P123"`. Values are raw QuickStatements tokens: item
  QIDs (`"Q750"`), dates (`"+2024-01-01T00:00:00Z/9"`), or plain
  quantities (`"42"`). All values in the list are applied uniformly to
  every row.

- ...:

  Additional named arguments passed to
  [`create_quick_statement()`](https://carwilb.github.io/wikitools/reference/create_quick_statement.md)
  (e.g., `type`, `reference_qid`, `reference_url`).

## Value

The input data frame with an additional `quick_statement` column.

## Examples

``` r
df <- data.frame(
  qid = c("Q750", "Q868"),
  population = c("10000000", "20000000"),
  stringsAsFactors = FALSE
)
df %>%
  add_quick_statement_column_q(
    qid, "P1082", population,
    qualifiers = list(P585 = "+2024-01-01T00:00:00Z/9"),
    type = "quantity"
  )
#> # A tibble: 2 × 3
#>   qid   population quick_statement                                         
#>   <chr> <chr>      <chr>                                                   
#> 1 Q750  10000000   Q750 | P1082 | 10000000 | P585 | +2024-01-01T00:00:00Z/9
#> 2 Q868  20000000   Q868 | P1082 | 20000000 | P585 | +2024-01-01T00:00:00Z/9
```
