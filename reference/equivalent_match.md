# Return Equivalent Strings from a Vector

Returns all elements of \`string_list\` that are equivalent to
\`string\` under \[str_equivalent()\] normalization (case, accents,
whitespace, non-breaking spaces, double quotes). Returns \`NA\` when no
match is found.

## Usage

``` r
equivalent_match(string, string_list)
```

## Arguments

- string:

  A character string to search for.

- string_list:

  A character vector to search in.

## Value

The matching elements of \`string_list\` as a character vector, or
\`NA\` if no equivalent is found. If multiple elements match, all are
returned.

## See also

\[str_equivalent()\], \[equivalent_which()\], \[str_equivalent_list()\]

## Examples

``` r
equivalent_match("café", c("cafe", "tea", "coffee"))  # "cafe"
#> [1] "cafe"
equivalent_match("hello", c("Hello", "world"))        # "Hello"
#> [1] "Hello"
equivalent_match("bye", c("Hello", "world"))          # NA
#> [1] NA
```
