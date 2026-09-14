# Parse a Wikitable HTML Node into a Tidy Tibble

Internal helper for \[get_wikitable()\]. Splits a \`\<table\>\` node's
rows into a leading run of header rows (rows composed entirely of
\`\<th\>\` cells) and the remaining body rows, merges a one- or two-row
header into flat column names, and expands each body row's \`colspan\`s
to a consistent width. Single-cell rows in the body (typically
legend/footnote rows spanning the whole table) are pulled out into
\`notes\` rather than treated as data. If \`extract_links = TRUE\`, any
row-header column with at least one article link gets an adjacent
\`\<name\>\_link\` column (see \[.expand_row_links()\]).

## Usage

``` r
.parse_wikitable_node(
  table_node,
  strip_citations = TRUE,
  drop_notes = TRUE,
  extract_links = TRUE,
  lang = "en"
)
```

## Arguments

- table_node:

  An \`xml_node\` for one \`\<table class="wikitable"\>\` element.

- strip_citations:

  Logical, forwarded to \[.cell_text()\]/\[.expand_row()\].

- drop_notes:

  Logical. If \`TRUE\` (default), single-cell body rows are removed from
  the data and returned via \`notes\` instead.

- extract_links:

  Logical. If \`TRUE\` (default), add a \`\<name\>\_link\` column
  immediately after any row-header column that contains article links
  (see \[.expand_row_links()\]).

- lang:

  Character. Wikipedia language code, forwarded to
  \[.expand_row_links()\] for building absolute URLs.

## Value

A list with elements \`data\` (tibble) and \`notes\` (character vector,
possibly empty).

## Details

Header structures deeper than two rows are not specially merged; the raw
\[rvest::html_table()\] output is returned instead, with a message.
