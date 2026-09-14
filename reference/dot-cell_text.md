# Get Cleaned Text from a Set of Table Cells

Internal helper. Extracts rendered text from table cells via
\[rvest::html_text2()\] and, optionally, strips bracketed citation
markers (e.g. \`"\[8\]"\`, \`"\[A\]"\`) that Wikipedia superscripts into
cell text.

## Usage

``` r
.cell_text(cells, strip_citations = TRUE)
```

## Arguments

- cells:

  An \`xml_nodeset\` of table cell elements.

- strip_citations:

  Logical. If \`TRUE\` (default), remove citation markers matching
  \`\\\[0-9\]+\\\` or \`\\\[A-Za-z\]\\\`.

## Value

Character vector, one value per cell.
