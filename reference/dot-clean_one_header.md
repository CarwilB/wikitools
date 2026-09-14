# Clean One Header String into a Snake-Case Variable Name

Internal helper for \[clean_column_headers()\]. Strips citation markers,
splits the string on whitespace or underscores, lower-cases each
resulting word unless it is entirely uppercase letters (an acronym like
\`"UK"\` or \`"AUS"\`), and rejoins the words with \`\_\`.

## Usage

``` r
.clean_one_header(x)
```

## Arguments

- x:

  Character scalar. One header string.

## Value

Character scalar. The cleaned, snake_case name.
