# Check for an Interactive Session

Thin wrapper around \[interactive()\] so tests can mock the
interactivity check (bindings in the base namespace cannot be mocked
reliably).

## Usage

``` r
is_interactive()
```

## Value

Logical, from \[interactive()\].
