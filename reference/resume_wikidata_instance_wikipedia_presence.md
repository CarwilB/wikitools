# Resume a partially completed Wikipedia presence query

If a prior call to \[wikidata_instance_wikipedia_presence()\] was
interrupted, pass its partial result here to fetch only the missing
instances and rebuild the full presence matrix.

## Usage

``` r
resume_wikidata_instance_wikipedia_presence(
  partial_result,
  class_qid,
  languages = NULL,
  country = NULL,
  limit = 1000,
  batch_size = 50,
  batch_delay = 1,
  include_labels = TRUE,
  drop_other_langs = TRUE,
  object_type = "instance"
)
```

## Arguments

- partial_result:

  List previously returned by
  \[wikidata_instance_wikipedia_presence()\]. Must contain
  \`\$instances\` with a \`qid\` column.

- class_qid:

  See \[wikidata_instance_wikipedia_presence()\].

- languages:

  See \[wikidata_instance_wikipedia_presence()\].

- country:

  See \[wikidata_instance_wikipedia_presence()\].

- limit:

  See \[wikidata_instance_wikipedia_presence()\].

- batch_size:

  See \[wikidata_instance_wikipedia_presence()\].

- batch_delay:

  See \[wikidata_instance_wikipedia_presence()\].

- include_labels:

  See \[wikidata_instance_wikipedia_presence()\].

- drop_other_langs:

  See \[wikidata_instance_wikipedia_presence()\].

- object_type:

  Character. \`"instance"\` or \`"subclass"\` or \`"position_held"\`

## Value

Same structure as \[wikidata_instance_wikipedia_presence()\].

## See also

\[wikidata_instance_wikipedia_presence()\],
\[resume_get_wikidata_instances()\]
