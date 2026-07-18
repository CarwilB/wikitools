# Parse a Wikidata Entity Record

Internal helper that parses one Wikidata entity into a named list record
for tabular binding.

## Usage

``` r
.parse_entity(
  entity,
  qid,
  property,
  property_names,
  languages,
  numeric_list_properties = NULL,
  numeric_list_property_names = NULL,
  object_type = "instance",
  verbose = FALSE
)
```

## Arguments

- entity:

  A single Wikidata entity object.

- qid:

  Character QID for the entity.

- property:

  Optional character vector of extra property IDs.

- property_names:

  Character vector of output names for \`property\`.

- languages:

  Character vector of language codes.

- numeric_list_properties:

  Optional character vector of numeric-list property IDs.

- numeric_list_property_names:

  Character vector of output prefixes.

- object_type:

  Character. \`"instance"\` or \`"subclass"\`.

- verbose:

  Logical. If \`TRUE\`, emit detailed parsing diagnostics.

## Value

A named list representing one parsed entity row.

## Details

Parse a Wikidata Entity Record
