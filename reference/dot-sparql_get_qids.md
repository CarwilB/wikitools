# Execute SPARQL Query and Return QIDs

Internal helper that executes the generated SPARQL query and extracts
item QIDs from the result set.

## Usage

``` r
.sparql_get_qids(class_qid, country, limit, property_id = "P31")
```

## Arguments

- class_qid:

  Character class QID.

- country:

  Optional character country QID.

- limit:

  Integer result limit.

- property_id:

  Character. \`"P31"\` or \`"P279"\`.

## Value

A character vector of QIDs.

## Details

Execute SPARQL Query and Return QIDs
