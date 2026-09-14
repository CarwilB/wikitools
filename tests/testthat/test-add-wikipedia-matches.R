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

  expect_false(any(result$wp_found))
  expect_false(any(result$wp_match))
  expect_true(all(is.na(result$wp_title)))
  expect_true(all(is.na(result$wp_url)))
  expect_true(all(is.na(result$wp_snippet)))
})

# --- Output structure --------------------------------------------------------

test_that("add_wikipedia_matches appends the five expected columns (default wp_ prefix)", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(poets[10, ], delay = 0)

  new_cols <- c("wp_found", "wp_match", "wp_title", "wp_url", "wp_snippet")
  expect_true(all(new_cols %in% names(result)))
})

test_that("output column types are correct", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(poets[10, ], delay = 0)

  expect_type(result$wp_found,   "logical")
  expect_type(result$wp_match,   "logical")
  expect_type(result$wp_title,   "character")
  expect_type(result$wp_url,     "character")
  expect_type(result$wp_snippet, "character")
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

test_that("wp_match is TRUE when title matches query (case- and space-normalized)", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Tracy K. Smith"), delay = 0)
  expect_true(result$wp_found)
  expect_true(result$wp_match)
})

test_that("wp_match is FALSE when a page is found but title differs from query", {
  # "Amy King (poet)" does not normalize to "amyking"
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Amy King (poet)"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Amy King"), delay = 0)
  expect_true(result$wp_found)
  expect_false(result$wp_match)
})

test_that("wp_found and wp_match are FALSE when search returns no results", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_not_found(),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Jane Beiles"), delay = 0)
  expect_false(result$wp_found)
  expect_false(result$wp_match)
  expect_true(is.na(result$wp_title))
  expect_true(is.na(result$wp_url))
})

# --- URL construction --------------------------------------------------------

test_that("wp_url is correctly constructed from the returned title", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Tracy K. Smith"), delay = 0)
  expect_equal(result$wp_url, "https://en.wikipedia.org/wiki/Tracy_K._Smith")
})

test_that("wp_url reflects the lang argument", {
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", ...) mock_found("Tishani Doshi", lang = lang),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Tishani Doshi"), lang = "es", delay = 0)
  expect_match(result$wp_url, "^https://es\\.wikipedia\\.org/wiki/")
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
  expect_true(result$wp_found)
  expect_true(result$wp_match)
})

# --- .shortname and .langname -------------------------------------------------

test_that(".shortname = FALSE restores the wikipedia_ prefix", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble(name = "Tracy K. Smith"), delay = 0, .shortname = FALSE)

  old_cols <- c("wikipedia_found", "wikipedia_match",
                "wikipedia_title", "wikipedia_url", "wikipedia_snippet")
  expect_true(all(old_cols %in% names(result)))
  expect_false(any(c("wp_found", "wp_match") %in% names(result)))
})

test_that(".langname = TRUE inserts the language code into wp_ column names", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(
    tibble(name = "Tracy K. Smith"), lang = "en", delay = 0, .langname = TRUE
  )

  lang_cols <- c("wp_en_found", "wp_en_match", "wp_en_title", "wp_en_url", "wp_en_snippet")
  expect_true(all(lang_cols %in% names(result)))
  expect_true(result$wp_en_found)
  expect_true(result$wp_en_match)
})

test_that(".langname = TRUE with .shortname = FALSE uses wikipedia_<lang>_ prefix", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) mock_found("Tishani Doshi", lang = "es"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(
    tibble(name = "Tishani Doshi"), lang = "es", delay = 0,
    .shortname = FALSE, .langname = TRUE
  )

  lang_cols <- c("wikipedia_es_found", "wikipedia_es_match",
                 "wikipedia_es_title", "wikipedia_es_url", "wikipedia_es_snippet")
  expect_true(all(lang_cols %in% names(result)))
})

test_that(".langname = TRUE allows combining results from multiple languages without collisions", {
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", ...) mock_found("Tracy K. Smith", lang = lang),
    .package = "wikitools"
  )
  base <- tibble(name = "Tracy K. Smith")
  result_en <- add_wikipedia_matches(base, lang = "en", delay = 0, .langname = TRUE)
  result_both <- add_wikipedia_matches(result_en, lang = "fr", delay = 0, .langname = TRUE)

  expect_true(all(c("wp_en_found", "wp_fr_found") %in% names(result_both)))
  expect_true(all(c("wp_en_match", "wp_fr_match") %in% names(result_both)))
})

# --- Vector `lang` (multi-language single call) --------------------------------

test_that("a vector `lang` searches each language and appends columns for all of them", {
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", ...) mock_found("Tracy K. Smith", lang = lang),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(
    tibble(name = "Tracy K. Smith"), lang = c("en", "fr", "cs"), delay = 0
  )

  for (lg in c("en", "fr", "cs")) {
    expect_true(all(paste0("wp_", lg, "_", c("found", "match", "title", "url", "snippet")) %in% names(result)))
  }
  expect_true(result$wp_en_found)
  expect_true(result$wp_fr_found)
  expect_true(result$wp_cs_found)
})

test_that("a vector `lang` forces .langname = TRUE even if the caller passes FALSE", {
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", ...) mock_found("Tracy K. Smith", lang = lang),
    .package = "wikitools"
  )
  expect_message(
    result <- add_wikipedia_matches(
      tibble(name = "Tracy K. Smith"), lang = c("en", "fr"), delay = 0, .langname = FALSE
    ),
    "forcing"
  )
  expect_true(all(c("wp_en_found", "wp_fr_found") %in% names(result)))
})

test_that("a vector `lang` produces per-language results that can differ (found vs. not found)", {
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", ...) {
      if (lang == "en") mock_found("Tracy K. Smith", lang = lang) else mock_not_found()
    },
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(
    tibble(name = "Tracy K. Smith"), lang = c("en", "cs"), delay = 0
  )

  expect_true(result$wp_en_found)
  expect_true(result$wp_en_match)
  expect_false(result$wp_cs_found)
  expect_false(result$wp_cs_match)
})

test_that("a vector `lang` respects .shortname = FALSE", {
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", ...) mock_found("Tracy K. Smith", lang = lang),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(
    tibble(name = "Tracy K. Smith"), lang = c("en", "fr"), delay = 0, .shortname = FALSE
  )

  expect_true(all(c("wikipedia_en_found", "wikipedia_fr_found") %in% names(result)))
})
