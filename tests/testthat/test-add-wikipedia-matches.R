library(testthat)
library(wikitools)
library(tibble)

poets <- tibble::tribble(
  ~name,              ~birth_year,
  "Jennifer Reeser",  1971,
  "Sabrina Benaim",   1974,
  "Julianna Baggott", 1975,
  "Chamila Kanchana", 1977,
  "Jane Beiles",      1977,
  "Margaret Ross",    1979,
  "Amy King",         1971,
  "Airea Matthews",   1974,
  "Shara McCallum",   1972,
  "Tracy K. Smith",   1972,
  "Tishani Doshi",    1975,
  "Shin Yu Pai",      1972
)

# Mimics search_wikipedia_one() returning a found result with a given title
mock_found <- function(title, lang = "en", snippet = "A poet born in the 1970s.") {
  title_for_url <- gsub(" ", "_", title)
  url <- paste0(
    "https://", lang, ".wikipedia.org/wiki/",
    utils::URLencode(title_for_url, reserved = TRUE)
  )
  list(found = TRUE, title = title, url = url, snippet = snippet)
}

# Mimics search_wikipedia_one() returning no result
mock_not_found <- function() {
  list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_)
}

# --- Input validation --------------------------------------------------------

test_that("add_wikipedia_matches errors when df is not a data frame", {
  expect_error(add_wikipedia_matches("not a dataframe"), "is.data.frame")
})

test_that("add_wikipedia_matches errors when name_col is absent from df", {
  expect_error(add_wikipedia_matches(poets, name_col = "nonexistent"), "name_col")
})

# --- NA and empty name handling (search_wikipedia_one returns early, no mock needed) ---

test_that("NA and blank names return found = FALSE without a search", {
  df <- tibble(name = c(NA_character_, "", "   "))
  result <- add_wikipedia_matches(df, delay = 0)

  expect_false(any(result$wikipedia_found))
  expect_false(any(result$wikipedia_match))
  expect_true(all(is.na(result$wikipedia_title)))
  expect_true(all(is.na(result$wikipedia_url)))
  expect_true(all(is.na(result$wikipedia_snippet)))
})

# --- Output structure --------------------------------------------------------

test_that("add_wikipedia_matches appends the five expected columns", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(poets[10, ], delay = 0)

  new_cols <- c("wikipedia_found", "wikipedia_match",
                "wikipedia_title", "wikipedia_url", "wikipedia_snippet")
  expect_true(all(new_cols %in% names(result)))
})

test_that("output column types are correct", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(poets[10, ], delay = 0)

  expect_type(result$wikipedia_found,   "logical")
  expect_type(result$wikipedia_match,   "logical")
  expect_type(result$wikipedia_title,   "character")
  expect_type(result$wikipedia_url,     "character")
  expect_type(result$wikipedia_snippet, "character")
})

test_that("output has the same number of rows as input", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Some Poet"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(poets, delay = 0)
  expect_equal(nrow(result), nrow(poets))
})

test_that("original columns and values are preserved", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(poets[10, ], delay = 0)

  expect_equal(result$name,       "Tracy K. Smith")
  expect_equal(result$birth_year, 1972)
})

test_that("tibble input produces tibble output", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(poets[10, ], delay = 0)
  expect_s3_class(result, "tbl_df")
})

# --- Match logic -------------------------------------------------------------

test_that("wikipedia_match is TRUE when title matches query (case- and space-normalized)", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Tracy K. Smith"), delay = 0)
  expect_true(result$wikipedia_found)
  expect_true(result$wikipedia_match)
})

test_that("wikipedia_match is FALSE when a page is found but title differs from query", {
  # "Amy King (poet)" does not normalize to "amyking"
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Amy King (poet)"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Amy King"), delay = 0)
  expect_true(result$wikipedia_found)
  expect_false(result$wikipedia_match)
})

test_that("wikipedia_found and wikipedia_match are FALSE when search returns no results", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_not_found(),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Jane Beiles"), delay = 0)
  expect_false(result$wikipedia_found)
  expect_false(result$wikipedia_match)
  expect_true(is.na(result$wikipedia_title))
  expect_true(is.na(result$wikipedia_url))
})

# --- URL construction --------------------------------------------------------

test_that("wikipedia_url is correctly constructed from the returned title", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Tracy K. Smith"), delay = 0)
  expect_equal(result$wikipedia_url, "https://en.wikipedia.org/wiki/Tracy_K._Smith")
})

test_that("wikipedia_url reflects the lang argument", {
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", ...) mock_found("Tishani Doshi", lang = lang),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Tishani Doshi"), lang = "es", delay = 0)
  expect_match(result$wikipedia_url, "^https://es\\.wikipedia\\.org/wiki/")
})

# --- Custom name_col ---------------------------------------------------------

test_that("add_wikipedia_matches works with a custom name_col", {
  df <- tibble(poet = "Shara McCallum", collection = "The Water Between Us")
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Shara McCallum"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(df, name_col = "poet", delay = 0)

  expect_true("poet"       %in% names(result))
  expect_true("collection" %in% names(result))
  expect_true(result$wikipedia_found)
  expect_true(result$wikipedia_match)
})
