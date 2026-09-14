# Matching Names to Wikipedia and Wikidata

``` r

library(wikitools)
library(dplyr)
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(stringr)
library(tidyr)
```

[`add_wikipedia_matches()`](https://carwilb.github.io/wikitools/reference/add_wikipedia_matches.md)
and
[`add_wikidata_matches()`](https://carwilb.github.io/wikitools/reference/add_wikidata_matches.md)
take a data frame with a column of names (or any search strings) and
look each one up – the former against a given language edition of
Wikipedia, the latter against Wikidata itself. Both append columns
recording whether something was found and whether it matches the query
exactly, plus identifying details of the top hit. This makes it easy to
check, at a glance, how well a list of names is covered by Wikipedia or
Wikidata – useful before pulling structured data, or before assuming an
article or item exists to link to.

The two functions differ in an important way that this article will
illustrate: **Wikipedia articles are language-specific pages**, one per
edition, so
[`add_wikipedia_matches()`](https://carwilb.github.io/wikitools/reference/add_wikipedia_matches.md)’s
`found` column reflects whether that particular language actually has an
article. **Wikidata items are language-agnostic entities** – a single
QID typically carries labels and aliases in dozens of languages – so
[`add_wikidata_matches()`](https://carwilb.github.io/wikitools/reference/add_wikidata_matches.md)
can often find *something* for a name in a language it has never been
written up in on Wikipedia. That makes Wikidata coverage look more
complete, but, as the example below shows, “found” and “the right
entity” aren’t always the same thing.

## A list of names

Here is a roster of writers and artists associated with the Paris
Surrealist group in the late 1920s, formatted the way it might appear in
an attendance list or archival index: surname in capitals, given name
after.

``` r

names_text <- "BRETON André
ÉLUARD Paul
PÉRET Benjamin
SADOUL Georges
UNIK Pierre
THIRION André
CREVEL René
ARAGON Louis
CHAR René
ALEXANDRE Maxime
TANGUY Yves
MALKINE Georges"
```

A short `tidyr`/`stringr` pipeline splits this into rows and separates
the surname (still in capitals) from the given name:

``` r

names_df <- names_text |>
  str_split("\n") |>
  unlist() |>
  str_trim() |>
  tibble(full = _) |>
  separate(full, into = c("last_name", "first_name"), sep = " ", extra = "merge") |>
  select(first_name, last_name)

names_df <- names_df |>
  mutate(last_name = str_to_title(last_name)) |>
  mutate(full_name = str_c(first_name, last_name, sep = " "))

names_df
#> # A tibble: 12 × 3
#>    first_name last_name full_name       
#>    <chr>      <chr>     <chr>           
#>  1 André      Breton    André Breton    
#>  2 Paul       Éluard    Paul Éluard     
#>  3 Benjamin   Péret     Benjamin Péret  
#>  4 Georges    Sadoul    Georges Sadoul  
#>  5 Pierre     Unik      Pierre Unik     
#>  6 André      Thirion   André Thirion   
#>  7 René       Crevel    René Crevel     
#>  8 Louis      Aragon    Louis Aragon    
#>  9 René       Char      René Char       
#> 10 Maxime     Alexandre Maxime Alexandre
#> 11 Yves       Tanguy    Yves Tanguy     
#> 12 Georges    Malkine   Georges Malkine
```

`full_name` is now in the “First Last” form that Wikipedia article
titles typically use, and is what we’ll search on.

## Matching against Wikipedia: English and Czech at once

`lang` accepts a vector of language codes, so a single call can check
coverage across multiple editions of Wikipedia. Each language’s results
land in the same tibble, distinguished by a language-coded prefix
(`wp_en_*`, `wp_cs_*`, …) rather than by separate objects:

``` r

names_df <- names_df |>
  select(first_name, last_name, full_name) |>
  add_wikipedia_matches("full_name", lang = c("en", "cs"), limit = 25)
#> Multiple `lang` values supplied; forcing `.langname = TRUE` to avoid column collisions.

names_df |>
  select(full_name, wp_en_found, wp_en_match, wp_cs_found, wp_cs_match)
#> # A tibble: 12 × 5
#>    full_name        wp_en_found wp_en_match wp_cs_found wp_cs_match
#>    <chr>            <lgl>       <lgl>       <lgl>       <lgl>      
#>  1 André Breton     TRUE        TRUE        TRUE        TRUE       
#>  2 Paul Éluard      TRUE        TRUE        TRUE        TRUE       
#>  3 Benjamin Péret   TRUE        TRUE        TRUE        TRUE       
#>  4 Georges Sadoul   TRUE        TRUE        TRUE        FALSE      
#>  5 Pierre Unik      TRUE        TRUE        TRUE        FALSE      
#>  6 André Thirion    TRUE        TRUE        TRUE        FALSE      
#>  7 René Crevel      TRUE        TRUE        TRUE        TRUE       
#>  8 Louis Aragon     TRUE        TRUE        TRUE        TRUE       
#>  9 René Char        TRUE        TRUE        TRUE        TRUE       
#> 10 Maxime Alexandre TRUE        TRUE        TRUE        FALSE      
#> 11 Yves Tanguy      TRUE        TRUE        TRUE        TRUE       
#> 12 Georges Malkine  TRUE        TRUE        TRUE        FALSE
```

(Passing more than one language forces `.langname = TRUE` automatically
– with a message – since without a language-coded prefix the `en` and
`cs` columns would otherwise collide.)

Every name in this group resolves to an English Wikipedia article whose
title matches the query exactly – `wp_en_match` is `TRUE` throughout.
That’s expected: these are well-documented figures from a
well-documented movement, and English Wikipedia’s coverage of
early-20th-century French Surrealism is thorough.

Coverage is rarely so complete on every language edition, though. The
`wp_cs_*` columns tell a different story: several names return *some*
Czech Wikipedia result (`wp_cs_found = TRUE`), but the top hit is not
actually an article about that person – it’s the closest fuzzy match the
search engine could find, such as a film title, an unrelated biography,
or a list article that happens to mention the name.
[`add_wikipedia_matches()`](https://carwilb.github.io/wikitools/reference/add_wikipedia_matches.md)
flags these as `wp_cs_match = FALSE` by comparing the returned title
against the query (case- and whitespace-insensitive), so they can be
filtered out rather than mistaken for a genuine match:

``` r

names_df |>
  filter(!wp_cs_match) |>
  select(full_name, wp_cs_title, wp_cs_snippet)
#> # A tibble: 5 × 3
#>   full_name        wp_cs_title                      wp_cs_snippet               
#>   <chr>            <chr>                            <chr>                       
#> 1 Georges Sadoul   Regarde les hommes tomber        "ho oblíbil, a kterého zata…
#> 2 Pierre Unik      Juraj Sagan                      "cyklista, aktuálně působíc…
#> 3 André Thirion    Seznam představitelů surrealismu "světě: <span class=\"searc…
#> 4 Maxime Alexandre Máxima Nizozemská                "<span class=\"searchmatch\…
#> 5 Georges Malkine  Lilian Malkina                   "Töpfer Nerušit, prosím, Di…
```

Only names with `wp_cs_match = TRUE` should be treated as confirmed
Czech-language coverage, and comparing the per-language match totals
makes the coverage gap explicit:

``` r

names_df |>
  summarise(
    n = n(),
    matched_en = sum(wp_en_match),
    matched_cs = sum(wp_cs_match)
  )
#> # A tibble: 1 × 3
#>       n matched_en matched_cs
#>   <int>      <int>      <int>
#> 1    12         12          7
```

## Matching against Wikidata: English and Czech at once

[`add_wikidata_matches()`](https://carwilb.github.io/wikitools/reference/add_wikidata_matches.md)
has the same interface – a vector `lang`, the same
`.shortname`/`.langname` conventions – but searches Wikidata’s
`wbsearchentities` endpoint instead of a Wikipedia edition’s search
index. That endpoint matches only entity **labels and aliases**, never
description text; the returned `description` is included in the output
for context, not as something the query is matched against. We can
append its columns straight onto the same `names_df` used above:

``` r

names_df <- names_df |>
  add_wikidata_matches("full_name", lang = c("en", "cs"), limit = 25)
#> Multiple `lang` values supplied; forcing `.langname = TRUE` to avoid column collisions.

names_df |>
  select(full_name, wd_en_found, wd_en_match, wd_cs_found, wd_cs_match)
#> # A tibble: 12 × 5
#>    full_name        wd_en_found wd_en_match wd_cs_found wd_cs_match
#>    <chr>            <lgl>       <lgl>       <lgl>       <lgl>      
#>  1 André Breton     TRUE        TRUE        TRUE        TRUE       
#>  2 Paul Éluard      TRUE        TRUE        TRUE        TRUE       
#>  3 Benjamin Péret   TRUE        TRUE        TRUE        TRUE       
#>  4 Georges Sadoul   TRUE        TRUE        TRUE        TRUE       
#>  5 Pierre Unik      TRUE        TRUE        TRUE        TRUE       
#>  6 André Thirion    TRUE        TRUE        TRUE        TRUE       
#>  7 René Crevel      TRUE        TRUE        TRUE        TRUE       
#>  8 Louis Aragon     TRUE        TRUE        TRUE        TRUE       
#>  9 René Char        TRUE        TRUE        TRUE        TRUE       
#> 10 Maxime Alexandre TRUE        TRUE        TRUE        TRUE       
#> 11 Yves Tanguy      TRUE        TRUE        TRUE        TRUE       
#> 12 Georges Malkine  TRUE        TRUE        TRUE        TRUE
```

Every name matches in both languages this time – a first sign of the
language-agnostic behavior described in the introduction. Because a
Wikidata item’s labels and aliases usually span many languages
regardless of which Wikipedia editions have written the person up,
[`add_wikidata_matches()`](https://carwilb.github.io/wikitools/reference/add_wikidata_matches.md)
tends to find *something* far more consistently across languages than
[`add_wikipedia_matches()`](https://carwilb.github.io/wikitools/reference/add_wikipedia_matches.md)
does.

That consistency comes with a catch, though. Comparing the QIDs returned
for each language turns up a mismatch:

``` r

names_df |>
  filter(wd_en_qid != wd_cs_qid) |>
  select(full_name, wd_en_qid, wd_en_description, wd_cs_qid, wd_cs_description)
#> # A tibble: 1 × 5
#>   full_name   wd_en_qid wd_en_description          wd_cs_qid wd_cs_description  
#>   <chr>       <chr>     <chr>                      <chr>     <chr>              
#> 1 Yves Tanguy Q164720   French painter (1900–1955) Q16103309 rozcestník na proj…
```

For this name, the Czech-language search’s top hit is a *different* item
than the English search’s – a Wikimedia disambiguation page, not the
painter. Both rows still report `wd_match = TRUE`, because the label
really did match the query exactly in both cases; the label alone can’t
distinguish a disambiguation page from a biography. This is exactly
where the `description` column earns its place in the output even though
it plays no part in `match`: reading it here immediately reveals that
the Czech hit isn’t the entity we were looking for, while the English
hit’s description identifies the actual person. Treat `wd_match = TRUE`
as “the text matched,” not as “this is the entity you meant,” and
spot-check `description` (or the QIDs themselves) whenever a name is
ambiguous or has a common form.

The `alias_match` column marks hits that matched via an alias rather
than the label – useful for exactly this kind of review, since alias
matches are more likely to need a second look. None of the surrealists
above needed one, but a quick example shows the distinction: searching a
well-known abbreviation resolves to the full label it stands for, with
the alias – not the label – registering as the match:

``` r

tibble(name = "NYC") |>
  add_wikidata_matches(lang = "en", delay = 0) |>
  select(name, wd_found, wd_match, wd_label, wd_alias_match)
#> # A tibble: 1 × 5
#>   name  wd_found wd_match wd_label      wd_alias_match
#>   <chr> <lgl>    <lgl>    <chr>         <lgl>         
#> 1 NYC   TRUE     TRUE     New York City TRUE
```

## Recap: Wikipedia vs. Wikidata match, side by side

Both sets of columns now live in the same `names_df`, so a final summary
table can put them next to each other for all 12 names at once:

``` r

names_df |>
  select(full_name, wp_en_match, wp_cs_match, wd_en_match, wd_cs_match)
#> # A tibble: 12 × 5
#>    full_name        wp_en_match wp_cs_match wd_en_match wd_cs_match
#>    <chr>            <lgl>       <lgl>       <lgl>       <lgl>      
#>  1 André Breton     TRUE        TRUE        TRUE        TRUE       
#>  2 Paul Éluard      TRUE        TRUE        TRUE        TRUE       
#>  3 Benjamin Péret   TRUE        TRUE        TRUE        TRUE       
#>  4 Georges Sadoul   TRUE        FALSE       TRUE        TRUE       
#>  5 Pierre Unik      TRUE        FALSE       TRUE        TRUE       
#>  6 André Thirion    TRUE        FALSE       TRUE        TRUE       
#>  7 René Crevel      TRUE        TRUE        TRUE        TRUE       
#>  8 Louis Aragon     TRUE        TRUE        TRUE        TRUE       
#>  9 René Char        TRUE        TRUE        TRUE        TRUE       
#> 10 Maxime Alexandre TRUE        FALSE       TRUE        TRUE       
#> 11 Yves Tanguy      TRUE        TRUE        TRUE        TRUE       
#> 12 Georges Malkine  TRUE        FALSE       TRUE        TRUE
```

English is a clean sweep across both sources. Czech is where the two
diverge: `wp_cs_match` is `FALSE` for several names – no matching
Wikipedia article exists in that edition – while `wd_cs_match` is `TRUE`
throughout, including for the Yves Tanguy row, where it matched the
disambiguation page rather than the person. Side by side, the table
makes the article’s central point concrete: a `TRUE` in the Wikidata
columns confirms a label or alias match, not confirmed Wikipedia
coverage or even the correct entity, whereas a `TRUE` in the Wikipedia
columns means an article by that exact title really does exist in that
language edition.

## Notes on usage

Shared conventions, for both
[`add_wikipedia_matches()`](https://carwilb.github.io/wikitools/reference/add_wikipedia_matches.md)
and
[`add_wikidata_matches()`](https://carwilb.github.io/wikitools/reference/add_wikidata_matches.md):

- **`lang`** can be a single code (`"en"`) or a vector
  (`c("en", "fr", "cs")`). With a vector, each function searches each
  language in turn and appends that language’s columns to the same
  output data frame – no need to run the function once per language and
  join the results yourself.
- **`.langname`** inserts the language code into column names
  (`wp_en_found` / `wd_en_found` rather than `wp_found` / `wd_found`).
  It defaults to `FALSE` for a single language, but is forced to `TRUE`
  whenever `lang` has more than one element.
- **`.shortname`** (default `TRUE`) controls the column prefix:
  `wp_`/`wd_` by default, or `wikipedia_`/`wikidata_` when set to
  `FALSE`.
- **`delay`** (default `0.5` seconds) pauses between requests to stay
  polite to the underlying API when checking many names; the pause
  applies between consecutive requests within each language. Set it to
  `0` for quick interactive checks on a handful of names, as in this
  article.

Specific to
[`add_wikipedia_matches()`](https://carwilb.github.io/wikitools/reference/add_wikipedia_matches.md):

- **`limit`** controls how many search results the API returns per
  query, but only the top result is ever used to populate the match
  columns. Raising it does not change matching behavior; it’s mainly
  useful if you plan to inspect `wp_*_snippet` or extend the function to
  consider alternate hits.
- Because matching is based on exact title equality, articles reachable
  only via a redirect, a disambiguating parenthetical (e.g. “Louis
  Aragon (poet)”), or an alternate spelling will show up as
  `wp_*_found = TRUE` but `wp_*_match = FALSE`. Treat those rows as
  needing manual review rather than as confirmed absences.

Specific to
[`add_wikidata_matches()`](https://carwilb.github.io/wikitools/reference/add_wikidata_matches.md):

- **`type`** (default `"item"`) is forwarded to `wbsearchentities`,
  letting you search Wikidata properties or lexemes instead of items.
- **`description`** and **`alias_match`** are informational: neither
  affects `match`. Use them to sanity-check hits, especially for common
  names – as the Yves Tanguy example above shows, `match = TRUE`
  guarantees the matched text was exact, not that the returned QID is
  the entity you meant.
- Because Wikidata items are shared across languages, `found`/`match`
  being `TRUE` in a given `lang` does not imply that language has any
  Wikipedia coverage of the entity – only that a label or alias exists
  for it in that language. Pair with
  [`add_wikipedia_matches()`](https://carwilb.github.io/wikitools/reference/add_wikipedia_matches.md)
  if actual article presence is what you need to confirm.
