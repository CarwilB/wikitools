# Expand One Table Row to a Fixed Column Width

Internal helper for \[get_wikitable()\]. Repeats each cell's text by its
\`colspan\`, then pads with \`NA\` (or truncates) so every row has
exactly \`total_cols\` values. Does not handle \`rowspan\` carried over
from a previous row into the table body.

## Usage

``` r
.expand_row(cells, total_cols, strip_citations = TRUE)
```

## Arguments

- cells:

  An \`xml_nodeset\` of one row's cells.

- total_cols:

  Integer. Target row length.

- strip_citations:

  Logical, forwarded to \[.cell_text()\].

## Value

Character vector of length \`total_cols\`.
