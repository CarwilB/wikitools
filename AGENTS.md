# wikitools R Package Development

## Project Goal

**Priority: Develop wikitools as a comprehensive, production-ready R package for Wikipedia and Wikidata tools.**

The wikitools package provides tools for retrieving, parsing, and matching Wikipedia and Wikidata content, including helpers for wikitext analysis and QuickStatements generation workflows.

### Key Objectives

1. **Complete Roxygen Documentation** - Ensure all 35 functions have full, high-quality Roxygen documentation
   - @title, @description, @param, @return, @examples for every function
   - @keywords internal for internal helper functions
   - @export for public functions only
   - Consistent documentation style across all files

2. **Comprehensive Unit Tests** - Build realistic unit tests for each function
   - Use testthat (3.0.0+) framework
   - Mock external API calls (Wikipedia, Wikidata, SPARQL)
   - Test edge cases and error handling
   - Aim for meaningful coverage, not just line coverage

3. **Code Quality** - Maintain high standards
   - Follow tidyverse style guide
   - Use base R pipe |> (not magrittr)
   - Clear, concise code with comments only where needed
   - Proper error messages and validation

## Package Structure

**Location:** `/Users/bjorkjcr/Dropbox/R/wikitools`

### Current Status (v0.1.0)

**Documentation:**
- ✅ DESCRIPTION file configured
- ✅ Basic package infrastructure
- ✅ 5 R source files with 35 functions
- ✅ All 35 .Rd man files generated
- ✅ 615 lines of Roxygen documentation
- ⚠️ Documentation varies in completeness:
  - get_wikidata_instances.R: 228 lines (well-documented)
  - wikipedia-tools.R: 144 lines (good)
  - create_quick_statement.R: 132 lines (good)
  - str-equivalent.R: 94 lines (adequate)
  - add-wikipedia-matches.R: 17 lines (needs work)

**Testing:**
- ✅ 230 total test lines across 3 test files
- ⚠️ Very uneven coverage:
  - test-str-equivalent.R: 126 lines (55%)
  - test-get_wikidata_instances.R: 101 lines (44%)
  - test-wikipedia-tools.R: 3 lines (1% — needs major expansion)
- ❌ Missing: test-add-wikipedia-matches.R, test-create-quick-statement.R
- ❌ No integration tests or API mocking fixtures

### Function Inventory

See `dev-notes/FUNCTION-INVENTORY.md` for comprehensive breakdown.

**Summary:**
- 35 total functions
- 28 exported functions
- 7 internal helper functions
- 5 source files organized by functionality

### Source Files

1. **R/wikipedia-tools.R** — Wikitext parsing utilities (no internet)
   - extract_clean_fragments, as_wikitable, extract_infobox, clean_infobox_value
   - count_citations, count_refs, extract_census_years, wikitext_to_plain

2. **R/get-wikipedia-text.R** — Wikipedia API fetch functions
   - get_wikitext_by_name, get_wikitext_by_revid, get_wikitext_from_url
   - get_wp_category_members, get_wp_subcategories, get_wp_category_pages
   - get_page_info_batch, cache_wikitext, get_plain_text

3. **R/get_wikidata_instances.R** — Wikidata instance/class retrieval
   - get_wikidata_instances, resume_get_wikidata_instances
   - SPARQL queries, batch API handling, entity parsing (13 functions)

4. **R/wikidata-presence.R** — Wikipedia language presence analysis
   - wikidata_instance_wikipedia_presence
   - resume_wikidata_instance_wikipedia_presence

5. **R/wikiblame.R** — Revision history and text tracing
   - get_revision_history_map, find_sentence_insertion
   - track_wikipedia_sentences (+ internal helpers)

6. **R/wiki-refs.R** — Citation reference extraction
   - extract_refs_from_wikitext (+ internal parsing helpers)

7. **R/create_quick_statement.R** — QuickStatements V1 command generation (4 functions)

8. **R/str-equivalent.R** — String matching utilities (4 functions)

9. **R/add-wikipedia-matches.R** — Wikipedia search with fallback strategies (1 function)

## Status Update (July 18, 2026)

✅ **MAJOR MILESTONE:** test-get-wikipedia-text.R created with 86 tests using httptest mocks
- All 8 API functions now covered: get_wikitext_by_name, get_wikitext_by_revid,
  get_wikitext_from_url, get_wp_category_members, get_wp_subcategories,
  get_wp_category_pages, get_page_info_batch, cache_wikitext, get_plain_text
- Fixtures captured from real Wikipedia API for Mark Twain, Ada Lovelace, Steve Biko,
  6 elements batch, and Category:Noble gases (pages + subcategories)
- Fixtures stored in tests/testthat/en.wikipedia.org/w/api.php-*.json
- Tests use httptest::with_mock_dir(".") pattern (httptest 4.x)
- Total package test suite: 343 tests, 0 failures

---

## Development Priorities

### Phase 1: Critical Testing Gaps ✅ COMPLETE
1. **test-wikipedia-tools.R** ✅ DONE
   - Expanded from 3 to 516 lines
   - 104 tests covering all text-processing functions
   - Zero-internet functions: extract_clean_fragments, as_wikitable, extract_infobox, clean_infobox_value, count_citations, count_refs, extract_census_years

2. **test-add-wikipedia-matches.R** ✅ DONE
   - 185 lines with 13+ test cases
   - Tests search, API fallbacks, error handling

3. **test-create-quick-statement.R** ✅ DONE
   - 451 lines with 30+ test cases
   - All statement types (string, monolingual, label, description, item, etc.)

### Phase 2: Code Organization ✅ COMPLETE
- [x] Extract API functions to get-wikipedia-text.R
  - get_wikitext_by_name()
  - get_wikitext_by_revid()
  - get_wikitext_from_url()
  - get_wp_category_members()
  - get_wp_subcategories()
  - get_wp_category_pages()
  - get_page_info_batch()
  - cache_wikitext()
- [x] wikipedia-tools.R now contains only text-processing functions
  - All functions are pure utilities with no internet access
  - All 104 tests in test-wikipedia-tools.R passing

### Phase 3: API Testing ✅ COMPLETE
- [x] Create test-get-wikipedia-text.R with httptest mocks (86 tests)
  - Real fixtures captured from Wikipedia API (9 fixture files)
  - Covers all 9 functions in get-wikipedia-text.R
  - Tests content, types, pagination output, caching, error handling

### Phase 3.5: Additional Testing (July 18, 2026)
- [x] test-wikidata-presence.R — 57 tests using Q978708 (PM of East Timor) fixture
  - Fixture: tests/testthat/fixtures/inst_q978708.rds (6 PMs, 84 language codes)
  - Uses local_mocked_bindings() — no API calls in tests
  - get_wikidata_instances() extended with object_type = "position_held" (P39)
  - wikidata_instance_wikipedia_presence() and resume_...() now accept object_type
- [x] test-wikiblame.R — 51 tests using Paul Rivet (121 revisions, httptest + synthetic mocks)
- [x] R/*.R file names converted to underscores (7 files renamed via git mv)
- [x] test-get_wikidata_instances.R — expanded to 53 tests
  - Covers: .build_sparql_query, .extract_instance_or_subclass, simplify_list_columns,
    .parse_entity (position_held branch), get_wikidata_instances integration (httptest),
    resume_get_wikidata_instances validation
  - Fixtures: query.wikidata.org/sparql-7ae1e7.R, www.wikidata.org/w/api.php-bd18af.json
- [x] test-search_wikipedia_one.R — 30 tests covering search_wikipedia_one() directly
  - Fixtures: api.php-48c94f.json (Paul Rivet search), api.php-72b8b1.json (no results)
  - Also covers add_wikipedia_matches() tryCatch, data.frame output, limit forwarding

### Phase 5: New Features (July 30-31, 2026)
- [x] Added `get_wikidata_items()` function
  - Takes predetermined list of QIDs instead of deriving via SPARQL
  - Reuses all existing helper functions (`.fetch_qids_in_batches`, `.parse_entity`, etc.)
  - Supports all same features: languages, properties, numeric_list_properties, object_type
  - Full Roxygen documentation + 10 unit tests added to test-get_wikidata_instances.R
  - All 411 package tests passing

- [x] Added `unpack_wikipedia_article_info()` function (July 31, 2026)
  - Unpacks list column of Wikipedia article info (from `get_wikidata_items()` or `get_wikidata_instances()`)
  - Takes format: `"lang_code: Article Title"`
  - Creates 3 columns per language: `{lang}_present` (logical), `{lang}_article` (character), `{lang}_url` (character)
  - Default languages: `c("en", "es")`, customizable via `langs` parameter
  - Custom column name supported via `wiki_col` parameter
  - Full Roxygen documentation + 14 comprehensive unit tests
  - All 704 package tests passing

- [x] Reworked `add_wikipedia_matches()` output column naming (Sept 12, 2026)
  - New param `.shortname` (default `TRUE`): output columns prefixed `wp_` instead of
    the old fixed `wikipedia_` prefix. Set `.shortname = FALSE` to restore the old prefix.
    **This changes the default output column names** from `wikipedia_found` etc. to `wp_found` etc.
  - New param `.langname` (default `FALSE`): when `TRUE`, inserts the language code into
    column names, e.g. `wp_en_found` / `wikipedia_en_found`. Lets results from multiple
    language editions (e.g. calling once per `lang` in `c("en", "fr", "cs")`) be bound into
    the same data frame without column collisions — a stepping-stone toward direct
    multi-language support (`lang = c("en", "fr", "cs")` in one call), planned next.
  - Consolidated a stray duplicate file `R/add-wikipedia-matches.R` (hyphenated, untracked)
    into the canonical `R/add_wikipedia_matches.R` (underscore-named, matches package
    file-naming convention). Only one file should ever define `add_wikipedia_matches()`/
    `search_wikipedia_one()` — check for duplicates before editing this function again.
  - Updated test-add-wikipedia-matches.R and test-search_wikipedia_one.R to expect `wp_*`
    columns by default; added dedicated tests for `.shortname` / `.langname` behavior.
  - Updated vignettes/articles/add-wikipedia-matches.Rmd to use `wp_*` column names.
  - All 712 package tests passing

- [x] `lang` in `add_wikipedia_matches()` now accepts a character vector (Sept 12, 2026)
  - `lang = c("en", "fr", "cs")` searches each language in turn and appends that
    language's five columns to the same output data frame in one call (no more
    manually calling once per language and joining results).
  - Supplying more than one language automatically forces `.langname = TRUE`
    (with a `message()`) since per-language column prefixes are required to
    avoid collisions; a single `lang` still defaults to `.langname = FALSE`.
  - `delay` still applies between consecutive requests *within* each language.
  - Added 4 new tests in test-add-wikipedia-matches.R covering: multi-language
    column creation, the `.langname` auto-force message, differing per-language
    results (found in one language but not another), and `.shortname = FALSE`
    with a vector `lang`.
  - Rewrote vignettes/articles/add-wikipedia-matches.Rmd to run a single
    `lang = c("en", "cs")` call and present both languages' match columns in
    one tibble side by side, rather than two separate calls/objects.
  - Reminder: after editing R/add_wikipedia_matches.R, run
    `devtools::install(quick = TRUE, upgrade = FALSE)` before re-rendering the
    article — `library(wikitools)` in the Rmd loads the *installed* package,
    not the `load_all()`-patched version from an interactive session.
  - All 725 package tests passing

- [x] Added `add_wikidata_matches()` and internal `search_wikidata_one()` (Sept 13, 2026)
  - New file `R/add_wikidata_matches.R`. Mirrors `add_wikipedia_matches()`'s design
    (same `.shortname`/`.langname`/vector-`lang` conventions) but targets Wikidata
    instead of Wikipedia.
  - Uses the `wbsearchentities` action of the Wikidata API (`www.wikidata.org/w/api.php`),
    which searches **labels and aliases only** in a given language — description
    text is never searched. This was a deliberate correction mid-build: the initial
    ask mentioned "description and alias fields," but `wbsearchentities` can't search
    descriptions anyway, so the implementation searches labels/aliases and returns
    description only as informational output (does not affect the `match` column).
  - Output columns per language (stem names): `found`, `match`, `qid`, `label`,
    `description`, `alias_match`, `url`. `alias_match` is `TRUE` when the API's
    `match.type` was `"alias"` rather than `"label"` — e.g. searching `"NYC"` returns
    `qid = "Q60"`, `label = "New York City"`, `alias_match = TRUE`, `match = TRUE`
    (because the matched alias text "NYC" equals the query exactly).
  - `match` uses the same convention as `add_wikipedia_matches()`: `TRUE` only when
    the API's exact matched text (`match.text`, whether label or alias) equals the
    query after case/whitespace normalization. A fuzzy/diacritic hit like searching
    `"Bogota"` and getting label `"Bogotá"` back is `found = TRUE, match = FALSE`.
  - Default prefix is `wd_` (`.shortname = TRUE`); `.shortname = FALSE` restores
    `wikidata_*`. `type` param (default `"item"`) is forwarded to `wbsearchentities`
    for searching properties/lexemes instead of items.
  - Test files: `tests/testthat/test-add-wikidata-matches.R` (mocked
    `search_wikidata_one()`, mirrors `test-add-wikipedia-matches.R` structure) and
    `tests/testthat/test-search_wikidata_one.R` (httptest fixtures under
    `tests/testthat/www.wikidata.org/w/`: `api.php-30653c.json` = "Paul Rivet" label
    match, `api.php-d7bd44.json` = "NYC" alias match, `api.php-cb3cf7.json` =
    no-results query).
  - All 837 package tests passing

- [x] Extended `vignettes/articles/add-wikipedia-matches.Rmd` to cover
  `add_wikidata_matches()` (Sept 13, 2026)
  - Same file, retitled "Matching Names to Wikipedia and Wikidata" (not
    renamed/split) — kept the surrealist-writers dataset flowing through
    both functions rather than starting a second article.
  - Added a "Matching against Wikidata" section running
    `add_wikidata_matches("full_name", lang = c("en", "cs"))` on the same
    `names_df` used for the Wikipedia section, appending `wd_*` columns
    onto the same growing tibble.
  - Live run turned up a genuinely useful teaching example, kept in the
    article: searching "Yves Tanguy" in Czech returns a *different* QID
    than English (a Wikimedia disambiguation-page item, not the painter),
    even though `wd_match = TRUE` in both languages — used to illustrate
    that `match` only confirms exact text equality, not that the returned
    QID is the intended entity, and that `description` (informational,
    not used in matching) is the practical way to catch this.
  - Also added a small standalone `"NYC"` example to demonstrate
    `alias_match` distinctly from the main dataset (none of the 12
    surrealists produced an alias match).
  - Reframed the intro paragraph around the key conceptual difference:
    Wikipedia articles are per-language pages (so `add_wikipedia_matches()`
    `found` reflects real per-edition article presence), while Wikidata
    items are language-agnostic entities with multilingual labels/aliases
    (so `add_wikidata_matches()` tends to find *something* far more
    consistently across languages — which is informative but not the same
    as confirmed Wikipedia coverage).
  - Restructured "Notes on usage" into a shared-conventions list plus
    function-specific sub-lists (`lang`/`.langname`/`.shortname`/`delay`
    shared; `limit`/title-equality caveat specific to Wikipedia;
    `type`/`description`/`alias_match`/cross-language caveat specific to
    Wikidata).
  - Re-installed the package (`devtools::install(quick = TRUE, upgrade = FALSE)`)
    and rendered the Rmd directly to confirm it knits; the disambiguation-page
    mismatch reproduced live, confirming it's a stable-enough example to keep
    (not a one-off API fluke) — worth re-checking if this article is
    re-rendered much later, in case Wikidata's data changes.
  - All 837 package tests passing (no test changes needed for this article-only update)
  - Added a "Recap: Wikipedia vs. Wikidata match, side by side" section at
    the end (before "Notes on usage") showing `wp_en_match`, `wp_cs_match`,
    `wd_en_match`, `wd_cs_match` together in one final tibble for all 12
    names — makes the central point visually obvious in one table: Czech
    Wikipedia has several `FALSE`s (no article) while Czech Wikidata is a
    clean sweep of `TRUE` (including the Yves Tanguy disambiguation-page
    case), so `wd_*_match = TRUE` confirms text equality, not confirmed
    Wikipedia coverage or the correct entity.

- [x] Added `get_wikitable()` (+ 4 internal helpers) and a new article
  `vignettes/articles/get-wikitable.Rmd` (Sept 13, 2026)
  - New file `R/get_wikitable.R`. This is the "retrieve a table" counterpart
    to `as_wikitable()` (which does the reverse: data frame → wikitext
    markup). No function like this existed anywhere in wikitools before —
    confirmed by checking `dev-notes/FUNCTION-INVENTORY.md` and the function
    list before starting. A `get_wikitable` was found only in the sibling
    `wiki-graph` project's function-inventory notes as an unmigrated
    candidate; couldn't locate/verify an actual implementation there
    (repeated `grep`/`ls` on `/Users/bjorkjcr/Dropbox/R/wiki-graph` timed
    out — that directory may be slow to traverse, e.g. Dropbox sync). Built
    fresh instead, using the `httr::GET` + `rvest::read_html` +
    `html_element(page, "table.wikitable")` + `html_table()` pattern shown
    in `../wiki-graph/import-ice-detention.qmd`'s `harmonize-with-wikipedia`
    chunk as a starting point (per user direction), then generalized it to:
    (a) select a specific table by matching a substring against its
    `<caption>` (not just "the first wikitable on the page", since most
    interesting pages have several), and (b) correctly parse the very common
    two-row `<th>` header pattern (e.g. a `rowspan="2"` "Title" column next
    to a `colspan="7"` "Peak chart positions" super-header whose real column
    names — "UK", "AUS", "US", etc. — sit on the second header row).
  - Fetches the **rendered HTML** article page directly (not wikitext via
    the API), since chart-position tables etc. only exist in rendered form.
  - Signature: `get_wikitable(article_name, lang = "en", match = NULL,
    index = 1, strip_citations = TRUE, drop_notes = TRUE)`. `match` takes
    precedence over `index` when supplied; errors list all available
    captions on the page if `match` doesn't hit anything (very useful in
    practice — this is how the ambiguous-caption case below was caught).
  - Returns a tibble of **character columns only** — Wikipedia table cells
    mix numbers, dashes, and footnoted text too unpredictably to safely
    auto-convert types; that's left to the caller (demonstrated in the
    article). Three attributes are attached: `"caption"`, `"url"`, `"notes"`.
  - Single-cell rows that span the full table width (the common
    "'—' denotes ..." legend row baked into the table body rather than
    placed as prose after it) are auto-detected and moved into the `"notes"`
    attribute instead of being treated as a data row (`drop_notes = TRUE`
    default; set `FALSE` to keep them, replicated across all columns).
  - Known limitation (documented in `@details`): body cells with `rowspan >
    1` are not specially handled, only two-row *headers* are. Header
    structures deeper than 2 rows fall back to plain `rvest::html_table()`
    with a message rather than attempting a general N-row header merge.
  - Internal helpers (all `@keywords internal`, all in the same file):
    `.cell_span()`, `.cell_text()` (strips `"[8]"`/`"[A]"`-style citation
    markers by default), `.merge_two_header_rows()`, `.expand_row()`,
    `.parse_wikitable_node()`.
  - Tests: `tests/testthat/test-get_wikitable.R` (38 tests). Internal
    helpers are tested against small hand-built HTML snippets; end-to-end
    `get_wikitable()` behavior is tested by mocking `httr::GET()` /
    `status_code()` / `content()` to serve a saved real page —
    `tests/testthat/fixtures/beatles_albums_discography.html` (captured
    from `en.wikipedia.org/wiki/The_Beatles_albums_discography`) — so no
    live network access is required to run the suite.
  - Added `ggplot2` and `tidyr` to `Suggests` in `DESCRIPTION` (needed by
    the new article's plotting/reshaping code; `tidyr` was already being
    used unlisted by `vignettes/articles/add-wikipedia-matches.Rmd`, so this
    also fixes a pre-existing gap there).
  - New article `vignettes/articles/get-wikitable.Rmd` uses `get_wikitable()`
    to fetch "List of studio albums, with selected chart positions and
    certification" from the same Beatles discography page, then walks
    through realistic cleanup: dash-to-NA + integer conversion on the 7
    chart-position columns, regex-extracting `released`/`label` out of the
    bulleted `Album details` cell, and reshaping the multi-line
    `Certifications` cell long with `tidyr::separate_longer_delim()` +
    `separate_wider_delim()`. Ends with a UK-vs-US peak-chart-position line
    plot (axis reversed since lower chart position = better) and a "where
    this could go next" pointer (joining certifications back to chart
    performance; other discography tables on the same page; enrichment via
    `add_wikidata_matches()`). Flagged as a first pass, not exhaustive.
  - Caught while building the article: the same page has a second,
    near-duplicate "...studio albums..." caption for a US-only release
    ("Introducing... The Beatles") — a real test case for `match`'s
    ambiguous-caption message, kept as a caveat note in the article.
  - Reminder: install before rendering this article too
    (`devtools::install(quick = TRUE, upgrade = FALSE)`) — same reason as
    the Wikipedia/Wikidata-matches article: `library(wikitools)` in an Rmd
    loads the installed package, not a `load_all()` session.
  - All 875 package tests passing

- [x] Added link extraction to `get_wikitable()`, plus new
  `clean_column_headers()` and `link_to_article_name()` (Sept 13, 2026)
  - `get_wikitable()` gained `extract_links = TRUE` (default). For each
    row-header column (`<th>` cells — Wikipedia's `plainrowheaders` style,
    typically the first column, e.g. `Title` in the Beatles table), if any
    cell links to another article, an adjacent `<name>_link` column is
    added holding the absolute URL. Ordinary `<td>` cells are **never**
    scanned for links, even when they contain one (e.g. a record-label
    link inside `Album details`) — deliberately narrow scope, so the
    default output stays predictable (one link column: the row's own
    subject) rather than growing a `_link` column for every incidental
    hyperlink in the table.
  - New internal helper `.expand_row_links()` (mirrors `.expand_row()`,
    refactored shared colspan/pad/truncate logic out into
    `.expand_vals()`); filters to hrefs containing `/wiki/` (so citation
    anchors like `#cite_note-1` are never picked up), and normalizes a
    relative `href` (`/wiki/Foo`) to an absolute URL using `lang`.
  - New exported `clean_column_headers(df)`: renames every column via new
    internal `.clean_one_header()` — strips citation markers (redundant
    safety net if `get_wikitable(strip_citations = FALSE)` was used),
    splits on whitespace *or* underscore (so a programmatically-built name
    like `"Title_link"` splits into `"Title"`/`"link"` same as a
    space-separated header), lower-cases each word **unless it's entirely
    uppercase letters** (preserves acronyms like `UK`/`AUS`), rejoins with
    `_`. On the Beatles table this turns `Title, Title_link, Album
    details, UK, AUS` into `title, title_link, album_details, UK, AUS` —
    the exact worked example requested.
  - New exported `link_to_article_name(link)`: vectorized, built directly
    from the `case_when(str_detect(link, "/wiki/") ~ {...}, TRUE ~
    NA_character_)` pattern in `../wiki-graph/import-ice-detention.qmd`'s
    `harmonize-with-wikipedia` chunk (per user direction) — extracts the
    `/wiki/` slug and replaces underscores with spaces; anything without
    `/wiki/` (including `NA`) returns `NA`.
  - Both new functions live in `R/get_wikitable.R` alongside
    `get_wikitable()` rather than a separate file, since they're tightly
    coupled to it (though `clean_column_headers()`/`link_to_article_name()`
    work on any data frame/character vector, not just `get_wikitable()`
    output).
  - Caught while testing: the linked article title is **not always** the
    same string as the display title — e.g. on this table, "Revolver"
    links to `Revolver (Beatles album)`, and `The Beatles ("The White
    Album")` links to plain `The Beatles (album)`. Documented as a
    `@details`-level caveat on `get_wikitable()` and called out explicitly
    in the article; a test asserts the Revolver case specifically rather
    than asserting `title_article == title` for every row (which is false).
  - 32 new tests added to `tests/testthat/test-get_wikitable.R` (38 → 70):
    unit tests for `.expand_row_links()`/`.expand_vals()` against small
    HTML snippets (th-only extraction, non-wiki-link filtering, relative
    → absolute URL), `.parse_wikitable_node()` link-column insertion/
    omission, `get_wikitable(extract_links = ...)` end-to-end against the
    existing Beatles fixture, and dedicated tests for both new exported
    functions (including the documented
    `clean_column_headers() |> mutate(title_article = link_to_article_name(title_link))`
    pipeline).
  - Updated `vignettes/articles/get-wikitable.Rmd`: new "Header names and
    article links" section runs the exact requested pipeline right after
    fetching, then all subsequent cleanup code was updated to the
    now-lowercase column names (`title`, `album_details`, `certifications`,
    `sales`; chart-position acronyms `UK`/`AUS`/etc. stay uppercase). The
    long-format certifications tibble was renamed from `certifications` to
    `album_certifications` to avoid colliding with the now-lowercased
    `certifications` column on `albums`.
  - Reminder (same as prior articles): re-run
    `devtools::install(quick = TRUE, upgrade = FALSE)` before re-rendering
    — confirmed necessary again this session (a stale installed build
    briefly caused a real render failure before reinstalling).
  - All 907 package tests passing

- [x] Added `find_wikipedia_matches()` and `choose_wikipedia_matches()` (Sept 13, 2026)
  - `R/find_wikipedia_matches.R`: exported `find_wikipedia_matches(x, n = 6,
    name_col, lang = "en", delay)` — the candidate-list counterpart to
    `add_wikipedia_matches()` (which keeps only the top hit). Accepts a
    character vector or data frame + `name_col`; returns a long tibble with
    one row per hit (`query`, `rank`, `match`, `title`, `url`, `snippet`);
    no-hit queries get one `NA` placeholder row. Internal helper
    `search_wikipedia_all()` returns all hits (tibble) instead of hit #1.
  - `R/choose_wikipedia_matches.R`: exported interactive picker
    `choose_wikipedia_matches()` built on `find_wikipedia_matches()` —
    shows each query's top `n` hits in `utils::menu()` with each article's
    **short description** appended (`"Title — description"`), plus a
    "None of these (skip)" option. Returns one row per query with
    `found`/`chosen`/`rank`/`title`/`url`/`description`.
  - Internal `get_short_descriptions(titles, lang)` fetches short
    descriptions via MediaWiki `prop=description`, batched 50/request;
    named character vector, `NA` on missing/error. Fixture:
    `tests/testthat/en.wikipedia.org/w/api.php-d3b04d.json` (Revolver titles —
    "Revolver" itself is the firearm article, good teaching case).
  - Internal `is_interactive()` wraps `interactive()` because base-namespace
    bindings **cannot be mocked** with `local_mocked_bindings()` (verified);
    tests mock `is_interactive` instead. Related gotcha learned: mocks
    registered in a test helper must use `.env = caller_env()` — the default
    caller frame tears them down when the helper returns, and
    `teardown_env()` leaks them across test files.
  - Beatles validation: human-verified `title_article` (from
    `get_wikitable()`'s link extraction) appears within the top 6 search
    candidates for all 12 studio albums, including cases where
    `add_wikipedia_matches()`'s top hit was the wrong entity ("With the
    Beatles" → band article; "A Hard Day's Night" → film at rank 1, album
    at rank 2).
  - All 982 package tests passing
  - `vignettes/articles/get-wikitable.Rmd` gained a "Choosing the right
    article interactively" section documenting `choose_wikipedia_matches()`
    and the reproducible-choices pattern: run the picker once interactively,
    `saveRDS()` the result (here `vignettes/articles/album_choices.rds`),
    and read it back with a `file.exists()` → readRDS / else interactive →
    run picker / else `stop()` guard so knitting works non-interactively.
    `album_choices.rds` was generated by picking the candidate whose title
    equals `title_article` (verified ranks: 1 for most, 2 for With the
    Beatles, A Hard Day's Night, Revolver). The comparison table in the
    article contrasts `chosen_title` against `add_wikipedia_matches()`'s
    automatic top hit (`wp_title`): 9/12 agree; the 3 divergences (With the
    Beatles → band article, A Hard Day's Night → film, Revolver → firearm,
    the last with `wp_match = TRUE`) are the teaching cases. The automatic
    hits are also cached (`vignettes/articles/album_auto_matches.rds`, same
    file.exists/readRDS/saveRDS guard) so the comparison is fully
    reproducible despite search-ranking drift.

### Phase 6: Polish & Release
- [ ] Run `devtools::check()` and fix all warnings/notes
- [ ] Create README.md with installation and usage examples
- [ ] Create vignette: "Getting Started with wikitools"
- [ ] Version bump to 0.2.0
- [ ] GitHub Actions CI/CD setup (optional)

## Dependencies

**Required:**
- dplyr
- httr
- jsonlite
- magrittr
- purrr
- rmarkdown
- rvest
- stringi
- stringr
- tibble

**Suggested:**
- testthat (≥3.0.0)
- knitr
- rmarkdown

## Related Projects

**wiki-graph** (`/Users/bjorkjcr/Dropbox/R/wiki-graph`) contains 141+ functions that extend or specialize wikitools for specific domains (Bolivia administrative boundaries, census data, Zotero integration, etc.). Consider promoting commonly-reusable functions from wiki-graph to wikitools over time.

### Migration Candidates from wiki-graph
- `get_plain_text()` - Wikipedia text extraction
- `extract_refs_from_wikitext()` - Reference extraction
- `wikidata_instance_wikipedia_presence()` - Presence checking
- `get_wikidata_frequencies()` - Frequency analysis
- `track_wikipedia_sentences()` - Edit tracking

## Notes

- All R code uses base R pipe `|>` (not magrittr)
- Package assumes user has configured R repositories
- Consider using httpcache or similar for local API response caching in tests
- Some functions already have basic inline documentation; need to convert to @-tags
- **Documentation Economy:** Maintain max 2 forms of documentation unless explicitly requested (e.g., primary: AGENTS.md + one other; avoid proliferation of separate docs)
