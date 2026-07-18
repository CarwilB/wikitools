# Build SPARQL Query for Class Retrieval

Internal helper that builds a SPARQL query for retrieving items by
\`instance of\` or \`subclass of\` with an optional country filter.

## Usage

``` r
.build_sparql_query(
  class_qid,
  country = NULL,
  property_id = "P31",
  limit = 1000
)
```

## Arguments

- class_qid:

  Character class QID.

- country:

  Optional character country QID.

- property_id:

  Character. \`"P31"\` or \`"P279"\`.

- limit:

  Integer result limit.

## Value

A character SPARQL query string.

## Details

Build SPARQL Query for Class Retrieval
