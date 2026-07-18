# Normalize and Compare Two Strings

Compares two character vectors for equivalence after applying a standard
set of normalizations: trimming leading/trailing whitespace, replacing
non-breaking spaces (\`\u00a0\`) with regular spaces, removing accents
via Latin-ASCII transliteration, removing double quotes, and ignoring
case.

## Usage

``` r
str_equivalent(x, y)
```

## Arguments

- x:

  A character vector.

- y:

  A character vector. Must be the same length as \`x\`, or length 1
  (recycled).

## Value

A logical vector the same length as the longer of \`x\` and \`y\`.
\`TRUE\` where the normalized strings are equal. Returns \`NA\` where
either input is \`NA\`.

## See also

\[equivalent_which()\], \[equivalent_match()\],
\[str_equivalent_list()\]

## Examples

``` r
str_equivalent("  Café", "cafe")                   # TRUE — accents + whitespace
#> [1] TRUE
str_equivalent("Hello\u00a0World", "hello world")  # TRUE — non-breaking space
#> [1] TRUE
str_equivalent('Quote"', "quote")                  # TRUE — double quote removed
#> [1] TRUE
str_equivalent("SUCRE", "sucre")                   # TRUE — case
#> [1] TRUE
str_equivalent("Mismatch", "mismatch!")             # FALSE
#> [1] FALSE
```
