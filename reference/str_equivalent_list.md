# Check Whether Any String in a Vector Is Equivalent

Returns \`TRUE\` if any element of \`string_list\` is equivalent to
\`string\` under \[str_equivalent()\] normalization (case, accents,
whitespace, non-breaking spaces, double quotes).

## Usage

``` r
str_equivalent_list(string, string_list)
```

## Arguments

- string:

  A character string to search for.

- string_list:

  A character vector of candidates.

## Value

A single logical value: \`TRUE\` if any element matches, \`FALSE\`
otherwise. Returns \`NA\` if no element matches and \`string_list\`
contains \`NA\` values.

## See also

\[str_equivalent()\], \[equivalent_which()\], \[equivalent_match()\]

## Examples

``` r
str_equivalent_list("café", c("cafe", "tea", "coffee"))  # TRUE
#> [1] TRUE
str_equivalent_list("hello", c("world", "hi"))           # FALSE
#> [1] FALSE
str_equivalent_list("x", character(0))                   # FALSE
#> [1] FALSE
```
