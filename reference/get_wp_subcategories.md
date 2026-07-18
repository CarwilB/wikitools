# Get Subcategories of a Wikipedia Category

Convenience wrapper around \[get_wp_category_members()\] that returns
only subcategories (\`type = "subcat"\`).

## Usage

``` r
get_wp_subcategories(category, lang = "en")
```

## Arguments

- category:

  Character. Category name, with or without \`"Category:"\` prefix.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A tibble with columns \`pageid\`, \`ns\`, and \`title\`.

## See also

\[get_wp_category_members()\], \[get_wp_category_pages()\]

## Examples

``` r
if (FALSE) { # \dontrun{
get_wp_subcategories("South American countries")
} # }
```
