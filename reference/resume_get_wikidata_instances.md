# Resume a Partially-Completed get_wikidata_instances() Query

Continues a partially completed class retrieval by skipping already
fetched QIDs and retrieving only remaining entities. Re-runs SPARQL to
get the full QID list, skips already retrieved entries, fetches the
remainder in batches, and returns a de-duplicated result.

## Usage

``` r
resume_get_wikidata_instances(
  partial_result,
  class_qid,
  property = NULL,
  property_names = NULL,
  country = NULL,
  languages = c("en", "es"),
  limit = 1000,
  batch_size = 50,
  batch_delay = 1,
  numeric_list_properties = NULL,
  numeric_list_property_names = NULL,
  entity_props = "labels|descriptions|claims|sitelinks",
  object_type = "instance",
  verbose = FALSE
)
```

## Arguments

- partial_result:

  A tibble previously returned (or partially returned) by
  [`get_wikidata_instances()`](https://carwilb.github.io/wikitools/reference/get_wikidata_instances.md).
  Must contain a `qid` column.

- class_qid:

  Character. Same value used in the original call.

- property:

  Character vector. Same value used in the original call.

- property_names:

  Character vector. Same value used in the original call.

- country:

  Character. Same value used in the original call.

- languages:

  Character vector. Same value used in the original call.

- limit:

  Integer. Default 1000.

- batch_size:

  Integer. Items per API request (max 50). Default 50.

- batch_delay:

  Numeric. Seconds between batches. Default 1.

- numeric_list_properties:

  Character vector. Same value used in the original call. Default
  `NULL`.

- numeric_list_property_names:

  Character vector. Same value used in the original call. Default
  `NULL`.

- entity_props:

  Character. Same value used in the original call. Default
  "labels\|descriptions\|claims\|sitelinks".

- object_type:

  Character. Either "instance" or "subclass". Default "instance". Must
  match the original call.

- verbose:

  Logical. If \`TRUE\`, print SPARQL query and detailed parse
  diagnostics.

## Value

A tibble with the same columns as
[`get_wikidata_instances()`](https://carwilb.github.io/wikitools/reference/get_wikidata_instances.md),
containing all items (previously retrieved + newly fetched).

## Details

Resume a Partially-Completed get_wikidata_instances() Query

## Examples

``` r
if (FALSE) { # \dontrun{
# Assuming municipalities_wd is a partial result from a prior call
municipalities_wd <- resume_get_wikidata_instances(
  municipalities_wd, "Q1062710",
  property                    = c("P131", "P17", "P14142"),
  property_names              = c("located_in", "country", "ine_code"),
  numeric_list_properties     = "P1082",
  numeric_list_property_names = "population"
)
} # }
```
