# Expand a Per-Cell Value Vector to a Fixed Column Width

Internal helper. Repeats each element of \`vals\` by its corresponding
\`colspan\`, then pads with \`NA\` (or truncates) so the result has
exactly \`total_cols\` values. Shared by \[.expand_row()\] (cell text)
and \[.expand_row_links()\] (cell links).

## Usage

``` r
.expand_vals(vals, colspans, total_cols)
```

## Arguments

- vals:

  A vector, one value per cell.

- colspans:

  Integer vector, one colspan per cell, same length as \`vals\`.

- total_cols:

  Integer. Target row length.

## Value

A vector of length \`total_cols\`, same type as \`vals\`.
