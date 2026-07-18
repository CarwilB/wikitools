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

  Character. Either "instance" (default) to retrieve items where P31
  (instance of) equals `class_qid`, or "subclass" to retrieve items
  where P279 (subclass of) equals `class_qid`.

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
get_wikidata_instances("Q250050", languages = c("en", "es"))
#> Found 10 instances. Retrieving details in batches of 50...
#>   Batch 1/1 (10 items)...
#> Successfully retrieved 10 items
#> # A tibble: 10 × 7
#>    qid      label_en          label_es description_en description_es instance_of
#>    <chr>    <chr>             <chr>    <chr>          <chr>          <list>     
#>  1 Q233169  Beni Department   Departa… department of… departamento … <chr [1]>  
#>  2 Q233917  Cochabamba Depar… Departa… department of… departamento … <chr [1]>  
#>  3 Q233933  Tarija Department Departa… department of… departamento … <chr [1]>  
#>  4 Q235106  Santa Cruz Depar… Departa… department of… departamento … <chr [1]>  
#>  5 Q235110  Chuquisaca Depar… Departa… department of… departamento … <chr [1]>  
#>  6 Q235362  Pando Department  Departa… department of… departamento … <chr [1]>  
#>  7 Q238079  Potosí Department Departa… department of… departamento … <chr [1]>  
#>  8 Q272784  La Paz Department Departa… department of… departamento … <chr [1]>  
#>  9 Q844510  Litoral           Departa… former depart… antiguo depar… <chr [3]>  
#> 10 Q1061368 Oruro Department  Departa… department of… departamento … <chr [1]>  
#> # ℹ 1 more variable: wikipedia_articles <list>

get_wikidata_instances(
  "Q1062710",
  property                    = c("P131", "P17", "P14142"),
  property_names              = c("located_in", "country", "ine_code"),
  numeric_list_properties     = "P1082",
  numeric_list_property_names = "population"
)
#> Found 341 instances. Retrieving details in batches of 50...
#>   Batch 1/7 (50 items)...
#>   Batch 2/7 (50 items)...
#>   Batch 3/7 (50 items)...
#>   Batch 4/7 (50 items)...
#>   Batch 5/7 (50 items)...
#>   Batch 6/7 (50 items)...
#>   Batch 7/7 (41 items)...
#> Successfully retrieved 341 items
#> # A tibble: 341 × 42
#>    qid     label_en    label_es description_en description_es located_in country
#>    <chr>   <chr>       <chr>    <chr>          <chr>          <list>     <chr>  
#>  1 Q121543 Villa Vaca… Villa V… municipality … municipio de … <chr [1]>  Q750   
#>  2 Q174806 Esmeralda   Esmeral… municipality … municipio bol… <chr [1]>  Q750   
#>  3 Q182203 Poroma      Poroma   municipality … municipio bol… <chr [2]>  Q750   
#>  4 Q195218 San Lorenzo San Lor… municipality … municipio bol… <chr [1]>  Q750   
#>  5 Q198351 Municipio … Ingavi   municipality … municipio bol… <chr [1]>  Q750   
#>  6 Q198348 Municipio … Sena     municipality … municipio bol… <chr [1]>  Q750   
#>  7 Q198355 Municipio … Puerto … municipality … municipio bol… <chr [1]>  Q750   
#>  8 Q198353 Bolpebra M… Municip… municipality … municipio bol… <chr [1]>  Q750   
#>  9 Q198359 Municipio … Santos … municipality … municipio bol… <chr [2]>  Q750   
#> 10 Q198357 Municipio … Villa N… municipality … municipio de … <chr [2]>  Q750   
#> # ℹ 331 more rows
#> # ℹ 35 more variables: ine_code <chr>, population <dbl>, population_n <int>,
#> #   population_1 <dbl>, population_1_year <int>, population_1_ref <chr>,
#> #   population_2 <dbl>, population_2_year <int>, population_2_ref <chr>,
#> #   population_3 <dbl>, population_3_year <int>, population_3_ref <chr>,
#> #   population_4 <dbl>, population_4_year <int>, population_4_ref <chr>,
#> #   population_5 <dbl>, population_5_year <int>, population_5_ref <chr>, …

# Retrieve subclasses instead of instances
get_wikidata_instances("Q34770", object_type = "subclass")
#> Found 111 subclasses. Retrieving details in batches of 50...
#>   Batch 1/3 (50 items)...
#>   Batch 2/3 (50 items)...
#>   Batch 3/3 (11 items)...
#> Successfully retrieved 111 items
#> # A tibble: 111 × 7
#>    qid        label_en        label_es description_en description_es subclass_of
#>    <chr>      <chr>           <chr>    <chr>          <chr>          <list>     
#>  1 Q104804164 artificial lan… lenguaj… language whic… NA             <chr [1]>  
#>  2 Q104925791 NA              NA       NA             NA             <chr [1]>  
#>  3 Q107031344 any language    NA       state of comm… NA             <chr [1]>  
#>  4 Q107617697 natiolect       NA       national vari… NA             <chr [1]>  
#>  5 Q123961776 monocentric la… NA       NA             NA             <chr [1]>  
#>  6 Q124156877 majority langu… lengua … NA             NA             <chr [1]>  
#>  7 Q132860982 religiolect     NA       Language vari… NA             <chr [3]>  
#>  8 Q135976069 indirective la… NA       language in w… NA             <chr [1]>  
#>  9 Q136193547 NA              NA       NA             NA             <chr [1]>  
#> 10 Q136193548 NA              NA       NA             NA             <chr [1]>  
#> # ℹ 101 more rows
#> # ℹ 1 more variable: wikipedia_articles <list>

get_wikidata_instances("Q4193029", property = "P1448",
  property_names = "official_name", verbose = TRUE)
#> SPARQL query:
#> SELECT DISTINCT ?item WHERE {
#>   ?item wdt:P31 wd:Q4193029 .
#> }
#> LIMIT 1000
#> Found 13 instances. Retrieving details in batches of 50...
#>   Batch 1/1 (13 items)...
#>     HTTP status code: 200
#>     Raw response (first 500 chars): {"entities":{"Q8679":{"type":"item","id":"Q8679","labels":{"nb":{"language":"nb","value":"Fiskene"},"fr":{"language":"fr","value":"Poissons"},"en":{"language":"en","value":"Pisces"},"it":{"language":"it","value":"Pesci"},"de":{"language":"de","value":"Fische"},"af":{"language":"af","value":"Visse"},"ar":{"language":"ar","value":"\u0627\u0644\u062d\u0648\u062a"},"be":{"language":"be","value":"\u0420\u044b\u0431\u044b"},"bg":{"language":"bg","value":"\u0420\u0438\u0431\u0438"},"bn":{"language":"bn
#>     QIDs in entities: Q8679, Q8842, Q8849, Q8853, Q8866, Q8865, Q8906, Q8923, Q10535, Q10570, Q10576, Q10580, Q10584
#> Successfully retrieved 13 items
#> # A tibble: 13 × 8
#>    qid    label_en    label_es    description_en    description_es official_name
#>    <chr>  <chr>       <chr>       <chr>             <chr>          <chr>        
#>  1 Q8679  Pisces      Piscis      zodiac constella… constelación   Pisces       
#>  2 Q8842  Virgo       Virgo       zodiac constella… constelación   Virgo        
#>  3 Q8849  Cancer      Cáncer      zodiac constella… constelación … Cancer       
#>  4 Q8853  Leo         Leo         zodiac constella… constelación   Leo          
#>  5 Q8866  Sagittarius Sagitario   zodiac constella… constelación … Sagittarius  
#>  6 Q8865  Scorpius    Escorpio    zodiac constella… constelación   Scorpius     
#>  7 Q8906  Ophiuchus   Ofiuco      zodiac constella… una de las co… Ophiuchus    
#>  8 Q8923  Gemini      Géminis     zodiac constella… constelación   Gemini       
#>  9 Q10535 Capricornus Capricornio zodiac constella… constelación … Capricornus  
#> 10 Q10570 Taurus      Tauro       zodiac constella… constelación … Taurus       
#> 11 Q10576 Aquarius    Acuario     zodiac constella… una de las co… Aquarius     
#> 12 Q10580 Libra       Libra       zodiac constella… constelación   Libra        
#> 13 Q10584 Aries       Aries       zodiac constella… constelación   Aries        
#> # ℹ 2 more variables: instance_of <list>, wikipedia_articles <list>
```
