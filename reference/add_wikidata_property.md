# Add a Wikidata Property to a Data Frame

Fetches a single-valued property from Wikidata and appends it as a new
column to a data frame that contains a \`qid\` column. Handles
entity-type, string, and time values and reports when multiple
statements are present for the requested property.

## Usage

``` r
add_wikidata_property(df, property, name = property)
```

## Arguments

- df:

  A data frame with a \`qid\` column.

- property:

  Character. Wikidata property ID (e.g., "P14142").

- name:

  Character. Name of the new column. Defaults to the property ID.

## Value

The input data frame with a new character column appended.

## Details

Add a Wikidata Property to a Data Frame

## Examples

``` r
departments <- tibble::tribble(
~qid,             ~label_en, ~cod.dep,
"Q233169",     "Beni Department",     "08",
"Q233917", "Cochabamba Department",     "03",
"Q233933",   "Tarija Department",     "06",
"Q235106", "Santa Cruz Department",     "07",
"Q235110", "Chuquisaca Department",     "01",
"Q235362",    "Pando Department",     "09",
"Q238079",   "Potosí Department",     "05",
"Q232784",    "La Paz Department",     "02",
"Q844510",             "Litoral",       NA,
"Q1061368",    "Oruro Department",     "04"
)
if (FALSE) { # \dontrun{
departments |> add_wikidata_property("P14142", name = "ine_code")
} # }
```
