# Get the Colspan or Rowspan of a Set of Table Cells

Internal helper. Reads a span attribute (\`"colspan"\` or \`"rowspan"\`)
off a set of \`\<th\>\`/\`\<td\>\` nodes, defaulting to \`1\` where the
attribute is absent.

## Usage

``` r
.cell_span(cells, attr_name)
```

## Arguments

- cells:

  An \`xml_nodeset\` of table cell elements.

- attr_name:

  Character. Either \`"colspan"\` or \`"rowspan"\`.

## Value

Integer vector, one value per cell.
