# Fetch QIDs from Wikidata in Batches

Internal helper that calls \`wbgetentities\` in batches and parses each
returned entity into row records.

## Usage

``` r
.fetch_qids_in_batches(
  qids,
  property,
  property_names,
  languages,
  batch_size = 20,
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

  Character vector of QIDs to fetch.

- property:

  Optional character vector of extra property IDs.

- property_names:

  Character vector of output names.

- languages:

  Character vector of languages for labels/descriptions.

- batch_size:

  Integer batch size.

- batch_delay:

  Numeric delay between batches.

- numeric_list_properties:

  Optional character vector of numeric-list property IDs.

- numeric_list_property_names:

  Character vector of output prefixes.

- entity_props:

  Character pipe-delimited \`wbgetentities\` props string.

- object_type:

  Character. \`"instance"\` or \`"subclass"\`.

- verbose:

  Logical. If \`TRUE\`, emit detailed parsing diagnostics.

## Value

A list of parsed entity records.

## Details

Fetch QIDs from Wikidata in Batches
