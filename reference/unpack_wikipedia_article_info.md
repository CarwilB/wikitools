# Unpack Wikipedia Article Information by Language

Extracts Wikipedia article information from a list column containing
language-tagged article titles (e.g., "en: Article Title") and creates
separate columns for each specified language. For each language, creates
three columns beginning with their lowercase letter code: e.g.,
\`en_present\` (logical), \`en_article\` (character), and \`en_url\`
(character).

## Usage

``` r
unpack_wikipedia_article_info(
  df,
  wiki_col = "wikipedia_articles",
  langs = c("en", "es")
)
```

## Arguments

- df:

  A data frame or tibble containing a column of Wikipedia article info.

- wiki_col:

  Name of the column containing Wikipedia article information (default:
  "wikipedia_articles"). Should contain character vectors with entries
  formatted as "lang_code: Article Title".

- langs:

  Character vector of language codes to extract (default: c("en",
  "es")). Language codes should match the format in the source data
  (e.g., "en", "es", "fr").

## Value

A tibble with the same rows as \`df\`, plus new columns for each
language beginning with their lowercase letter code: - \`LANG_present\`:
Logical indicating whether an article exists in that language -
\`LANG_article\`: Character string of the article title (NA if not
present) - \`LANG_url\`: Character string of the Wikipedia URL (e.g.,
"https://en.wikipedia.org/wiki/Article_Title")

## Details

The function searches for entries matching the pattern "lang_code: " in
the Wikipedia articles list. Article titles are converted to URL-safe
format by replacing spaces with underscores.

## Examples

``` r
if (FALSE) { # \dontrun{
# Given wiki_special_info with wikipedia_articles column
result <- unpack_wikipedia_article_info(
  wiki_special_info,
  wiki_col = "wikipedia_articles",
  langs = c("en", "es", "fr")
)

# New columns added:
# en_present, en_article, en_url
# es_present, es_article, es_url
# fr_present, fr_article, fr_url
} # }
```
