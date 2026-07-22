# Fetch Wikitext for a Specific Revision Safely

Retrieves the raw wikitext of a Wikipedia revision by ID. Handles both
the modern slot-based API response format and the legacy \`"\*"\` field.
Returns \`NULL\` rather than erroring if the revision is inaccessible.

## Usage

``` r
get_revision_text_safe(revid, lang = "en")
```

## Arguments

- revid:

  Numeric or character. Wikipedia revision ID.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A character string of wikitext, or \`NULL\` if not retrievable.

## See also

\[find_sentence_insertion()\], \[get_wikitext_by_revid()\]
