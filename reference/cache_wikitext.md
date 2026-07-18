# Cache Wikitext Locally

Fetches and stores article wikitext as a plain-text file, returning the
cached copy on subsequent calls without an API request. Useful when
processing many articles or re-running analyses repeatedly.

## Usage

``` r
cache_wikitext(title, cache_dir, lang = "en")
```

## Arguments

- title:

  Character. Wikipedia page title.

- cache_dir:

  Character. Path to the directory where cached \`.txt\` files are
  stored. The directory must already exist.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A character string of wikitext, or \`NULL\` if the page is not found.
When a cached file exists, it is read and returned without an API call.

## Details

File names are derived from the article title with the characters \`/ :
\* ? " \< \> \|\` replaced by underscores.

## See also

\[get_wikitext_by_name()\], \[extract_clean_fragments()\],
\[extract_infobox()\]

## Examples

``` r
if (FALSE) { # \dontrun{
dir.create("wikitext_cache", showWarnings = FALSE)
wt <- cache_wikitext("Sucre", cache_dir = "wikitext_cache", lang = "es")
# Second call reads from disk, no API request made
wt <- cache_wikitext("Sucre", cache_dir = "wikitext_cache", lang = "es")
} # }
```
