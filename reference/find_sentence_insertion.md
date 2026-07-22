# Find the Revision Where a Sentence Was First Inserted

Uses binary search over a Wikipedia article's revision history to
identify the revision in which a given sentence (or substring) first
appears. Makes one API call per binary-search step, so an article with
1,000 revisions requires at most ~10 calls.

## Usage

``` r
find_sentence_insertion(article, sentence, lang = "en", history_map = NULL)
```

## Arguments

- article:

  Character. Wikipedia article title.

- sentence:

  Character. The exact text to search for (case-sensitive, literal
  match).

- lang:

  Character. Wikipedia language code (default \`"en"\`).

- history_map:

  Data frame as returned by \[get_revision_history_map()\]. If \`NULL\`,
  the history is fetched automatically — pass a pre-fetched map when
  searching for multiple sentences in the same article.

## Value

A one-row data frame with columns \`revid\`, \`timestamp\`, and \`user\`
for the revision that first contains \`sentence\`, or \`NULL\` if the
sentence is not found in the revision history.

## See also

\[track_wikipedia_sentences()\], \[get_revision_history_map()\]

## Examples

``` r
if (FALSE) { # \dontrun{
result <- find_sentence_insertion("Anthropology", "the scientific study")
} # }
```
