# Wikipedia language presence matrix for instances of a Wikidata class

Builds a presence matrix where rows are Wikidata items (instances of a
class) and columns are Wikipedia language codes, indicating whether each
language edition of Wikipedia has an article for that item.

## Usage

``` r
wikidata_instance_wikipedia_presence(
  class_qid,
  languages = NULL,
  country = NULL,
  limit = 1000,
  batch_size = 50,
  batch_delay = 1,
  include_labels = TRUE,
  drop_other_langs = TRUE,
  object_type = "instance",
  debug = FALSE
)
```

## Arguments

- class_qid:

  Character. Wikidata QID of the class (e.g. \`"Q5"\` for human).

- languages:

  Character vector of Wikipedia language codes to track (e.g. \`c("en",
  "es", "pt", "qu")\`), or \`NULL\` to auto-discover all languages
  present across the returned instances.

- country:

  Character. Optional Wikidata QID to filter instances by country (e.g.
  \`"Q750"\` for Bolivia). Forwarded to \[get_wikidata_instances()\].

- limit:

  Integer. Maximum number of instances to retrieve. Forwarded to
  \[get_wikidata_instances()\].

- batch_size:

  Integer. API batch size. Forwarded to \[get_wikidata_instances()\].

- batch_delay:

  Numeric. Seconds to wait between batches. Forwarded to
  \[get_wikidata_instances()\].

- include_labels:

  Logical. If \`TRUE\`, include \`label_en\` and \`label_es\` columns
  from \[get_wikidata_instances()\] in the output data tibble.

- drop_other_langs:

  Logical. If \`TRUE\` (default) and \`languages\` is not \`NULL\`,
  sitelinks for languages not in \`languages\` are ignored.

- debug:

  Logical. If \`TRUE\`, attach a \`\$debug\` element to the return value
  with notes on handling of missing/deleted items.

## Value

A named list with three elements:

- \`instances\`:

  Tibble returned by \[get_wikidata_instances()\].

- \`presence\`:

  Logical matrix \`\[n_items × n_languages\]\` indicating presence in
  each Wikipedia edition.

- \`data\`:

  Tibble with \`qid\` (plus optional label columns) followed by one
  integer (0/1) column per language.

## Details

Uses \[get_wikidata_instances()\] to retrieve items and their sitelinks,
then derives language presence from the \`wikipedia_articles\`
list-column.

## See also

\[get_wikidata_instances()\],
\[resume_wikidata_instance_wikipedia_presence()\]

## Examples

``` r
if (FALSE) { # \dontrun{
res <- wikidata_instance_wikipedia_presence(
  class_qid = "Q5",
  languages = c("en", "es", "pt", "de", "qu"),
  limit = 500
)
head(res$data)

# Auto-discover all Wikipedia language codes present in sitelinks
res2 <- wikidata_instance_wikipedia_presence(
  class_qid = "Q5",
  languages = NULL,
  limit = 200
)
} # }
```
