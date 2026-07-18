# Find Positions of Equivalent Strings in a Vector

Returns the indices of elements in \`string_list\` that are equivalent
to \`string\` under \[str_equivalent()\] normalization (case, accents,
whitespace, non-breaking spaces, double quotes).

## Usage

``` r
equivalent_which(string, string_list)
```

## Arguments

- string:

  A character string to search for.

- string_list:

  A character vector to search in.

## Value

An integer vector of matching positions, or \`integer(0)\` if none
match.

## See also

\[str_equivalent()\], \[equivalent_match()\], \[str_equivalent_list()\]

## Examples

``` r
equivalent_which("café", c("cafe", "tea", "coffee"))  # 1
#> [1] 1
equivalent_which("hello", c("world", "Hello"))        # 2
#> [1] 2
equivalent_which("nope", c("a", "b", "c"))            # integer(0)
#> integer(0)
```
