# Get Members of a Wikipedia Category

Returns pages and/or subcategories belonging to a Wikipedia category.
Handles MediaWiki API pagination automatically, so categories with more
than 500 members are fully retrieved.

## Usage

``` r
get_wp_category_members(category, type = "page", lang = "en")
```

## Arguments

- category:

  Character. Category name, with or without the \`"Category:"\` prefix
  (it is added automatically if absent).

- type:

  Character. Which members to return: \`"page"\` (articles only),
  \`"subcat"\` (subcategories only), or \`"page\|subcat"\` (both).
  Default is \`"page"\`.

- lang:

  Character. Wikipedia language code (default \`"en"\`).

## Value

A tibble with columns:

- pageid:

  Integer. MediaWiki page ID.

- ns:

  Integer. MediaWiki namespace (0 = article, 14 = category).

- title:

  Character. Page title including namespace prefix.

Returns a zero-row tibble if the category is empty or not found.

## See also

\[get_wp_subcategories()\], \[get_wp_category_pages()\],
\[get_page_info_batch()\]

## Examples

``` r
if (FALSE) { # \dontrun{
get_wp_category_members("Capitals of South America")
get_wp_category_members("Capitals of South America", type = "subcat")
} # }
```
