# Merge a Two-Row Wikitable Header into One Set of Column Names

Internal helper for \[get_wikitable()\]. Many Wikipedia tables (e.g.
discography tables with a "Peak chart positions" super-header spanning
several country columns) use a two-row \`\<th\>\` header, where cells
with \`rowspan="2"\` apply to both rows and cells with \`colspan \> 1\`
are broken out into per-column sub-headers on the second row. This walks
both rows in parallel to reconstruct one flat vector of column names.

## Usage

``` r
.merge_two_header_rows(row1_cells, row2_cells, strip_citations = TRUE)
```

## Arguments

- row1_cells:

  An \`xml_nodeset\` of the first header row's cells.

- row2_cells:

  An \`xml_nodeset\` of the second header row's cells.

- strip_citations:

  Logical, forwarded to \[.cell_text()\].

## Value

Character vector of column names, one per data column.
