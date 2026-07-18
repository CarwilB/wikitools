# Extract Instance/Subclass QIDs

Internal helper that extracts all P31 (instance of) or P279 (subclass
of) target QIDs from one entity.

## Usage

``` r
.extract_instance_or_subclass(entity, property_id = "P31")
```

## Arguments

- entity:

  A single Wikidata entity object.

- property_id:

  Character. Either \`"P31"\` or \`"P279"\`.

## Value

A character vector of QIDs.

## Details

Extract Instance/Subclass QIDs
