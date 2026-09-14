# Clean the Column Headers of a Wikitable into Variable Names

Converts the raw header text returned by \[get_wikitable()\] (or any
data frame) into snake_case variable names: whitespace is replaced with
\`\_\`, citation markers like \`"\[8\]"\`/\`"\[A\]"\` are discarded, and
each word is lower-cased unless it is entirely uppercase (an acronym
such as \`"UK"\` or \`"AUS"\` is left as-is so it stays recognizable).

## Usage

``` r
clean_column_headers(df)
```

## Arguments

- df:

  A data frame or tibble.

## Value

\`df\` with cleaned column names. Row and column data are unchanged.

## See also

\[get_wikitable()\], \[link_to_article_name()\]

## Examples

``` r
if (FALSE) { # \dontrun{
albums <- get_wikitable(
  "The Beatles albums discography",
  match = "List of studio albums, with selected chart positions and certification"
)
albums <- clean_column_headers(albums)
names(albums)[1:5] # "title" "title_link" "album_details" "UK" "AUS"
} # }
```
