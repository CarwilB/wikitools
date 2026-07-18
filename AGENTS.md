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

1. **R/wikipedia-tools.R** (17 functions)
   - Wikipedia text fetching and caching
   - Wikitext parsing (infoboxes, citations, census years)
   - Category management
   - Page metadata retrieval

2. **R/get_wikidata_instances.R** (13 functions)
   - Wikidata instance/class retrieval
   - SPARQL queries
   - Batch API handling
   - Entity parsing

3. **R/create_quick_statement.R** (4 functions)
   - QuickStatements V1 command generation
   - Support for various data types and references

4. **R/str-equivalent.R** (4 functions)
   - String matching with accent/case/whitespace handling
   - Index and match utilities

5. **R/add-wikipedia-matches.R** (1 function)
   - Wikipedia search with fallback API strategies

## Development Priorities

### Phase 1: Critical Testing Gaps
1. **test-wikipedia-tools.R** - Expand from 3 to ~50+ lines
   - Mock Wikipedia API responses
   - Test wikitext extraction, parsing, fragment cleaning
   - Test category member retrieval
   - Test page info batch retrieval

2. **test-add-wikipedia-matches.R** (NEW)
   - Create comprehensive test suite
   - Mock Wikipedia search API
   - Test fallback to direct API calls
   - Test error handling for bad queries

3. **test-create-quick-statement.R** (NEW)
   - Test all statement types (string, monolingual, label, description, item, etc.)
   - Test reference handling
   - Test qualifier syntax
   - Test edge cases (special characters, nulls, LAST keyword)

### Phase 2: Documentation Enhancement
- [ ] Audit each function's @param and @return tags
  - Priority: add-wikipedia-matches.R (only 17 Roxygen lines)
- [ ] Add realistic @examples to all functions
  - Ensure examples don't require external API calls
  - Use mock data or commented examples
- [ ] Standardize documentation style across all files
- [ ] Add @seealso cross-references between related functions

### Phase 3: Polish & Release
- [ ] Create README.md with installation and usage examples
- [ ] Create vignette: "Getting Started with wikitools"
- [ ] Create vignette: "Wikidata Workflows"
- [ ] Run `devtools::check()` and fix all warnings/notes
- [ ] Add codecov badge to README
- [ ] Version bump to 0.2.0
- [ ] Consider CRAN submission

## Dependencies

**Required:**
- dplyr
- httr
- jsonlite
- stringi
- stringr
- tibble
- WikipediR

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
