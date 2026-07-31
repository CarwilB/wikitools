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
