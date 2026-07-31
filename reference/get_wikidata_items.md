# Get Wikidata Items by QID

Fetches detailed information for a predetermined list of Wikidata items
(QIDs) with labels, descriptions, optional properties, and linked
Wikipedia article titles. Unlike
[`get_wikidata_instances()`](https://carwilb.github.io/wikitools/reference/get_wikidata_instances.md),
this function takes a direct list of QIDs instead of discovering them
via SPARQL.

Items are fetched from the Wikidata API in batches of `batch_size`
(default 50, the API maximum) to avoid rate-limiting errors.

## Usage

``` r
get_wikidata_items(
  qids,
  property = NULL,
  property_names = NULL,
  languages = c("en", "es"),
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

- qids:

  Character vector. The Wikidata QIDs to fetch (e.g.,
  `c("Q42", "Q123")`).

- property:

  Character or character vector. Optional property ID(s) to retrieve as
  additional columns (e.g., `"P131"` or `c("P131", "P17")`). Default is
  `NULL`.

- property_names:

  Character vector. Column names to use for the extra properties.
  Default is `NULL` (use property IDs as column names).

- languages:

  Character vector. Language codes for labels and descriptions. Default
  is c("en", "es").

- batch_size:

  Integer. Number of items per API request (max 50). Default is 50.

- batch_delay:

  Numeric. Seconds to wait between batches. Default is 1.

- numeric_list_properties:

  Character vector of property IDs (e.g., `"P1082"`) whose values are
  Wikidata quantity statements that may have multiple claims (e.g.
  population figures across years). These must NOT also appear in
  `property`. For each property named `pname` in
  `numeric_list_property_names`, the following columns are added:

  pname

  :   Most recent value (numeric; sorted by P585 year desc).

  pname_n

  :   Total number of claims (integer).

  pname_1 ... pname_10

  :   Individual values (numeric).

  pname_1_year ... pname_10_year

  :   Year from P585 qualifier (integer).

  pname_1_ref ... pname_10_ref

  :   Reference URL (P854) or `"wd:Qxxx"` (P248), or `NA` (character).

- numeric_list_property_names:

  Character vector. Column name prefixes for each entry in
  `numeric_list_properties`. Defaults to the property IDs if `NULL`.

- entity_props:

  Character. Pipe-separated list of Wikidata entity props to request
  from `wbgetentities` (e.g. "labels\|sitelinks"). Default is
  "labels\|descriptions\|claims\|sitelinks".

- object_type:

  Character. Controls how data is parsed; does not affect the SPARQL
  query (since items are predetermined). Default is "instance".

  "instance"

  :   Extracts P31 (instance of) values.

  "subclass"

  :   Extracts P279 (subclass of) values.

  "position_held"

  :   Extracts P39 (position held) values.

- verbose:

  Logical. If \`TRUE\`, print detailed parse diagnostics.

## Value

A tibble with columns: - qid - label\_\<lang\>, description\_\<lang\>
for each language - Columns from `property` and
`numeric_list_properties` - instance_of (if object_type="instance"),
subclass_of (if object_type="subclass"), or position_held (if
object_type="position_held") - wikipedia_articles

## Details

Get Wikidata Items by QID

## Examples

``` r
if (FALSE) { # \dontrun{
# Fetch multiple items by QID
get_wikidata_items(c("Q42", "Q123"), languages = c("en", "es"))

# Fetch with additional properties
get_wikidata_items(
  c("Q42", "Q123"),
  property                    = c("P131", "P17"),
  property_names              = c("located_in", "country")
)
} # }
```
