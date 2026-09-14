# Extract Row-Header Article Links from One Table Row

Internal helper for \[get_wikitable()\]. For each cell in a row, if the
cell is a row-header (\`\<th\>\`, as in Wikipedia's common
\`plainrowheaders\` table style – typically just the first cell, e.g. an
album or place name) and contains a link to another Wikipedia article,
returns that link's absolute URL; otherwise \`NA\`. Ordinary \`\<td\>\`
cells never produce a link, even if they contain one (e.g. a "Label:"
link inside an "Album details" cell) – only the row-header column is a
candidate, keeping the default output focused on the one link most
likely to be useful (a link to the row's own subject).

## Usage

``` r
.expand_row_links(cells, total_cols, lang = "en")
```

## Arguments

- cells:

  An \`xml_nodeset\` of one row's cells.

- total_cols:

  Integer. Target row length.

- lang:

  Character. Wikipedia language code, used to build an absolute URL if a
  link's \`href\` is relative (e.g. \`"/wiki/Foo"\`).

## Value

Character vector of length \`total_cols\`, \`NA\` where no row-header
link was found.
