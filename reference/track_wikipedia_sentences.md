# Track Insertion Dates for Multiple Wikipedia Sentences

Fetches the revision history once for an article, then binary-searches
for each sentence in \`sentence_list\`, returning a tidy data frame with
one row per sentence recording who added it and when.

## Usage

``` r
track_wikipedia_sentences(article, sentence_list, lang = "en")
```

## Arguments

- article:

  Character. Wikipedia article title.

- sentence_list:

  Character vector of sentences (or substrings) to locate. Each is
  searched with a case-sensitive literal match.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A data frame with columns:

- \`original_sentence\`:

  The input sentence.

- \`added_by\`:

  Wikipedia username of the editor who inserted it, or \`NA\` if not
  found.

- \`date_added\`:

  ISO 8601 timestamp of that revision, or \`NA\`.

- \`revision_id\`:

  Revision ID integer, or \`NA\`.

## See also

\[find_sentence_insertion()\], \[get_revision_history_map()\]

## Examples

``` r
if (FALSE) { # \dontrun{
sentences <- c(
  "is the scientific study of humanity",
  "a method of analysing social or cultural interaction"
)
track_wikipedia_sentences("Anthropology", sentences)
} # }
```
