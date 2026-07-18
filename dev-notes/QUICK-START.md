# wikitools Development Quick Start

**Project Status:** Building production-ready R package (v0.1.0 → v0.2.0)

## Essential Files

| File | Purpose | When to use |
|------|---------|-----------|
| **AGENTS.md** | Master development plan & goals | Starting a session, planning work |
| **docs/FUNCTION-INVENTORY.md** | Complete function reference | Looking up what exists |
| **docs/DEVELOPMENT-STATUS.md** | Visual progress tracker | Checking what needs work |
| **docs/QUICK-START.md** | This file | Quick reference |

## Today's Priority: Tests & Docs

### What's Working ✅
- All 35 functions implemented
- 615 lines of Roxygen documentation
- Basic tests for 2/5 files (str-equivalent, get_wikidata_instances)

### What Needs Work ⚠️
- **test-wikipedia-tools.R**: Only 3 lines (expand to 50+)
- **test-add-wikipedia-matches.R**: Missing (create 30 lines)
- **test-create-quick-statement.R**: Missing (create 40 lines)
- **add-wikipedia-matches.R**: Only 17 Roxygen lines (expand to 40+)

## Your Next Task Checklist

### If expanding tests:
1. Pick a test file from the priority list above
2. Look at existing tests in `tests/testthat/` for patterns
3. Create mocks for Wikipedia/Wikidata API responses
4. Write 5-10 realistic test cases per function
5. Reference: `docs/DEVELOPMENT-STATUS.md` → "Functions by Priority"

### If improving documentation:
1. Open the R file needing work
2. Look at a well-documented file (e.g., get_wikidata_instances.R)
3. Enhance @param, @return, @examples
4. Ensure examples use realistic data (mock if needed)
5. Run `devtools::document()` to regenerate .Rd files

## Key Commands

```r
# Regenerate documentation from Roxygen comments
devtools::document()

# Run tests
devtools::test()

# Check package for issues
devtools::check()

# Load package for testing
devtools::load_all()
```

## File Structure

```
wikitools/
├── R/                          # Source code (5 files, 35 functions)
│   ├── wikipedia-tools.R       (17 functions)
│   ├── get_wikidata_instances.R (13 functions)
│   ├── create_quick_statement.R (4 functions)
│   ├── str-equivalent.R         (4 functions)
│   └── add-wikipedia-matches.R  (1 function)
├── tests/testthat/             # Unit tests (3 files, 230 lines)
│   ├── test-wikipedia-tools.R  (3 lines - NEEDS EXPANSION)
│   ├── test-str-equivalent.R   (126 lines ✅)
│   ├── test-get_wikidata_instances.R (101 lines ✅)
│   └── fixtures/               (API response mocks)
├── man/                        # Generated .Rd help files (35)
├── docs/                       # Documentation
│   ├── FUNCTION-INVENTORY.md   (catalog of functions)
│   ├── DEVELOPMENT-STATUS.md   (progress dashboard)
│   └── QUICK-START.md          (this file)
├── AGENTS.md                   # Development plan
└── DESCRIPTION                 # Package metadata

```

## Testing Patterns

Looking at existing tests? Key patterns used:

```r
# From test-str-equivalent.R
test_that("str_equivalent ignores case", {
  expect_true(str_equivalent("Hello", "hello"))
})

# From test-get_wikidata_instances.R
test_that("simplify_list_columns handles empty lists", {
  df <- data.frame(x = list(character(0)), y = 1)
  result <- simplify_list_columns(df)
  expect_equal(result$x, NA_character_)
})

# For API mocking, see fixtures/ directory
```

## Documentation Pattern

Looking at well-documented files? Pattern from get_wikidata_instances.R:

```r
#' Short Title
#'
#' @title Longer Title Here
#' @description Detailed explanation of what the function does,
#'   including edge cases and important notes.
#'
#' @param x Description of parameter x
#' @param y Description of parameter y
#'
#' @return What the function returns
#'
#' @examples
#' # Example code here (should not require external APIs)
#' result <- my_function(x = "value")
#'
#' @export
my_function <- function(x, y) {
  # code here
}
```

## Quick Links

- **GitHub:** https://github.com/CarwilB/wikitools
- **Project Plan:** See AGENTS.md
- **Function Reference:** docs/FUNCTION-INVENTORY.md
- **Progress Dashboard:** docs/DEVELOPMENT-STATUS.md

## Remember

- Use base R pipe `|>` (not magrittr `%>%`)
- Mock external API calls in tests
- Add realistic but self-contained examples
- Document all @export functions fully
- Mark internal functions with @keywords internal

---

**Last Updated:** July 17, 2026  
**Current Goal:** Reach v0.2.0 with complete tests & docs
