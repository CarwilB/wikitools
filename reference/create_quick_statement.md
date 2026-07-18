# Create QuickStatements V1 Syntax Commands

Generate QuickStatements commands for various data types including
strings, monolingual text, labels, and descriptions with optional
references.

## Usage

``` r
create_quick_statement(
  qid,
  property,
  value,
  lang = NULL,
  type = "string",
  retrieved_date = NULL,
  reference_url = NULL,
  reference_qid = NULL,
  qualifiers = NULL,
  comment = NULL
)
```

## Arguments

- qid:

  Character. The Wikidata item ID (e.g., "Q42")

- property:

  Character. The property ID (e.g., "P31" for statements, "L" for
  labels, "D" for descriptions, "A" for aliases)

- value:

  Character. The value to add

- lang:

  Character. Language code (required for monolingual text, labels,
  descriptions, and aliases). Default is NULL.

- type:

  Character. Type of value: "string", "monolingual", "label",
  "description", "alias", "item", "time", "quantity", "coordinate".
  Default is "string".

- retrieved_date:

  Character or Date. Date to use as retrieved date. If NULL (default),
  uses current system date. Only used if `reference_url` or
  `reference_qid` is provided.

- reference_url:

  Character. URL to use as reference (P854). If provided, a reference
  block is added to the statement. Default is NULL.

- reference_qid:

  Character. Wikidata item QID to use as a "stated in" (P248) reference.
  If provided, a reference block is added to the statement. Default is
  NULL.

- qualifiers:

  List. Optional list of qualifiers as name-value pairs (e.g., list(P585
  = "+2020-01-01T00:00:00Z/11")).

- comment:

  Character. Optional edit summary comment.

## Value

Character string containing the QuickStatements command

## Details

For more on QuickStatements syntax, see
https://www.wikidata.org/wiki/Help:QuickStatements or
https://meta.wikimedia.org/wiki/QuickStatements_3.0

## Examples

``` r
# String value
create_quick_statement("Q14579", "P348", "6.13.7")
#> [1] "Q14579 | P348 | \"6.13.7\""

# Monolingual text
create_quick_statement("Q935", "P1559", "Isaac Newton",
                      lang = "en", type = "monolingual")
#> [1] "Q935 | P1559 | en:\"Isaac Newton\""

# Label; using either type = "label" or property = "L" is sufficient
create_quick_statement("Q1001", property = "L", "Mahatma Gandhi",
                      lang = "en", type = "label")
#> [1] "Q1001 | Len | \"Mahatma Gandhi\""

# Description; using either type = "description" or property = "D" is sufficient
create_quick_statement("Q1001", property = "D",
                      "Indian independence activist (1869-1948)",
                      lang = "en", type = "description")
#> [1] "Q1001 | Den | \"Indian independence activist (1869-1948)\""

# With reference URL
create_quick_statement("Q42", "P19", "Q350", type = "item",
                      reference_url = "https://example.com")
#> [1] "Q42 | P19 | Q350 | S854 | \"https://example.com\" | S813 | +2026-07-18T00:00:00Z/11"

# With stated-in reference
create_quick_statement("Q42", "P19", "Q350", type = "item",
                      reference_qid = "Q36578")
#> [1] "Q42 | P19 | Q350 | S248 | Q36578 | S813 | +2026-07-18T00:00:00Z/11"
```
