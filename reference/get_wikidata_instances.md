# Get All Instances of a Wikidata Class

Retrieves all instances (P31) or subclasses (P279) of a given class from
Wikidata with labels, descriptions, optional properties, and linked
Wikipedia article titles.

Items are fetched from the Wikidata API in batches of `batch_size`
(default 50, the API maximum) to avoid rate-limiting errors.

## Usage

``` r
get_wikidata_instances(
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

- class_qid:

  Character. The Wikidata QID of the class (e.g., "Q250050")

- property:

  Character or character vector. Optional property ID(s) to retrieve as
  additional columns (e.g., `"P131"` or `c("P131", "P17")`). Default is
  `NULL`.

- property_names:

  Character vector. Column names to use for the extra properties.
  Default is `NULL` (use property IDs as column names).

- country:

  Character. Optional Wikidata QID of a country (e.g., "Q750" for
  Bolivia). Default is `NULL` (no country filter).

- languages:

  Character vector. Language codes for labels and descriptions. Default
  is c("en", "es").

- limit:

  Integer. Maximum number of results to return. Default is 1000.

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

  Character. Controls which Wikidata property is used for the SPARQL
  query:

  "instance"

  :   P31 (instance of) — the default.

  "subclass"

  :   P279 (subclass of).

  "position_held"

  :   P39 (position held) — retrieves items (typically persons) that
      have held the specified office or position. Adds a
      \`position_held\` list-column to the result.

- verbose:

  Logical. If \`TRUE\`, print SPARQL query and detailed parse
  diagnostics.

## Value

A tibble with columns: - qid - label\_\<lang\>, description\_\<lang\>
for each language - Columns from `property` and
`numeric_list_properties` - instance_of (if object_type="instance") or
subclass_of (if object_type="subclass") - wikipedia_articles

## Details

Get All Instances of a Wikidata Class

## Examples

``` r
if (FALSE) { # \dontrun{
get_wikidata_instances("Q250050", languages = c("en", "es"))

get_wikidata_instances(
  "Q1062710",
  property                    = c("P131", "P17", "P14142"),
  property_names              = c("located_in", "country", "ine_code"),
  numeric_list_properties     = "P1082",
  numeric_list_property_names = "population"
)

# Retrieve subclasses instead of instances
get_wikidata_instances("Q34770", object_type = "subclass")

get_wikidata_instances("Q4193029", property = "P1448",
  property_names = "official_name", verbose = TRUE)
} # }
```
