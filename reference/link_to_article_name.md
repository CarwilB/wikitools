# Extract a Wikipedia Article Name from a Link

Parses a Wikipedia article URL (or \`href\`, absolute or relative) and
returns the plain article title, with underscores replaced by spaces.
Values that don't contain \`"/wiki/"\` (including \`NA\`) return \`NA\`.

## Usage

``` r
link_to_article_name(link)
```

## Arguments

- link:

  Character vector of URLs/hrefs, such as the \`\_link\` columns added
  by \[get_wikitable()\].

## Value

Character vector of article titles, same length as \`link\`.

## See also

\[get_wikitable()\], \[clean_column_headers()\]

## Examples

``` r
link_to_article_name("https://en.wikipedia.org/wiki/Please_Please_Me")
#> [1] "Please Please Me"
link_to_article_name("/wiki/A_Hard_Day%27s_Night")
#> [1] "A Hard Day%27s Night"
link_to_article_name(c("https://en.wikipedia.org/wiki/Help!", NA, "not a link"))
#> [1] "Help!" NA      NA     
```
