library(testthat)
library(wikitools)
library(tibble)

poets <- tibble::tribble(
  ~name,              ~birth_year,
  "Jennifer Reeser",  1971,
  "Sabrina Benaim",   1974,
  "Julianna Baggott", 1975,
  "Tracy K. Smith",   1972,
  "Tishani Doshi",    1975
)

# Mimics search_wikidata_one() returning a label match
mock_label_match <- function(qid, label, description = "A poet born in the 1970s.") {
  list(
    found = TRUE, qid = qid, label = label, description = description,
    alias_match = FALSE, match_text = label,
    url = paste0("https://www.wikidata.org/wiki/", qid)
  )
}

# Mimics search_wikidata_one() returning an alias match (matched text != label)
mock_alias_match <- function(qid, label, alias, description = "A city.") {
  list(
    found = TRUE, qid = qid, label = label, description = description,
    alias_match = TRUE, match_text = alias,
    url = paste0("https://www.wikidata.org/wiki/", qid)
  )
}

# Mimics search_wikidata_one() returning no result
mock_not_found <- function() {
  list(found = FALSE, qid = NA_character_, label = NA_character_,
       description = NA_character_, alias_match = NA, match_text = NA_character_,
       url = NA_character_)
}

# --- Input validation --------------------------------------------------------

test_that("add_wikidata_matches errors when df is not a data frame", {
  expect_error(add_wikidata_matches("not a dataframe"), "is.data.frame")
})

test_that("add_wikidata_matches errors when name_col is absent from df", {
  expect_error(add_wikidata_matches(poets, name_col = "nonexistent"), "name_col")
})

# --- NA and empty name handling (search_wikidata_one returns early, no mock needed) ---

test_that("NA and blank names return found = FALSE without a search", {
  df <- tibble(name = c(NA_character_, "", "   "))
  result <- add_wikidata_matches(df, delay = 0)

  expect_false(any(result$wd_found))
  expect_false(any(result$wd_match))
  expect_true(all(is.na(result$wd_qid)))
  expect_true(all(is.na(result$wd_label)))
  expect_true(all(is.na(result$wd_description)))
  expect_true(all(is.na(result$wd_url)))
})

# --- Output structure --------------------------------------------------------

test_that("add_wikidata_matches appends the seven expected columns (default wd_ prefix)", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(poets[4, ], delay = 0)

  new_cols <- c("wd_found", "wd_match", "wd_qid", "wd_label",
                "wd_description", "wd_alias_match", "wd_url")
  expect_true(all(new_cols %in% names(result)))
})

test_that("output column types are correct", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(poets[4, ], delay = 0)

  expect_type(result$wd_found,       "logical")
  expect_type(result$wd_match,       "logical")
  expect_type(result$wd_qid,         "character")
  expect_type(result$wd_label,       "character")
  expect_type(result$wd_description, "character")
  expect_type(result$wd_alias_match, "logical")
  expect_type(result$wd_url,         "character")
})

test_that("output has the same number of rows as input", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q1", "Some Poet"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(poets, delay = 0)
  expect_equal(nrow(result), nrow(poets))
})

test_that("original columns and values are preserved", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(poets[4, ], delay = 0)

  expect_equal(result$name,       "Tracy K. Smith")
  expect_equal(result$birth_year, 1972)
})

test_that("tibble input produces tibble output", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(poets[4, ], delay = 0)
  expect_s3_class(result, "tbl_df")
})

test_that("add_wikidata_matches returns data.frame (not tibble) for data.frame input", {
  df <- data.frame(name = "Tracy K. Smith", stringsAsFactors = FALSE)
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(df, delay = 0)
  expect_s3_class(result, "data.frame")
  expect_false(inherits(result, "tbl_df"))
})

# --- Match logic (labels) -----------------------------------------------------

test_that("wd_match is TRUE when the matched label equals the query (case- and space-normalized)", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "Tracy K. Smith"), delay = 0)
  expect_true(result$wd_found)
  expect_true(result$wd_match)
  expect_false(result$wd_alias_match)
})

test_that("wd_match is FALSE when a hit is found but the matched text differs from the query", {
  # Fuzzy/diacritic match: query "Bogota" matches label "Bogotá", not identical
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q2841", "Bogot\u00e1"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "Bogota"), delay = 0)
  expect_true(result$wd_found)
  expect_false(result$wd_match)
})

test_that("wd_found and wd_match are FALSE when search returns no results", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_not_found(),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "xkjzqmnoexist"), delay = 0)
  expect_false(result$wd_found)
  expect_false(result$wd_match)
  expect_true(is.na(result$wd_qid))
  expect_true(is.na(result$wd_label))
})

# --- Match logic (aliases) ----------------------------------------------------

test_that("an exact alias match sets wd_match = TRUE and wd_alias_match = TRUE with a differing label", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_alias_match("Q60", "New York City", "NYC"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "NYC"), delay = 0)

  expect_true(result$wd_found)
  expect_true(result$wd_match)
  expect_true(result$wd_alias_match)
  expect_equal(result$wd_label, "New York City")
})

test_that("wd_alias_match is NA when no result is found", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_not_found(),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "xkjzqmnoexist"), delay = 0)
  expect_true(is.na(result$wd_alias_match))
})

# --- description is informational, not used for matching ----------------------

test_that("wd_description is populated but does not affect wd_match", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith", description = "American poet"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "Tracy K. Smith"), delay = 0)
  expect_equal(result$wd_description, "American poet")
  expect_true(result$wd_match)
})

test_that("wd_description is NA when found = FALSE", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_not_found(),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "xkjzqmnoexist"), delay = 0)
  expect_true(is.na(result$wd_description))
})

# --- URL construction --------------------------------------------------------

test_that("wd_url is correctly constructed from the returned qid", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "Tracy K. Smith"), delay = 0)
  expect_equal(result$wd_url, "https://www.wikidata.org/wiki/Q7831207")
})

# --- Custom name_col ---------------------------------------------------------

test_that("add_wikidata_matches works with a custom name_col", {
  df <- tibble(poet = "Shara McCallum", collection = "The Water Between Us")
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q1", "Shara McCallum"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(df, name_col = "poet", delay = 0)

  expect_true("poet"       %in% names(result))
  expect_true("collection" %in% names(result))
  expect_true(result$wd_found)
  expect_true(result$wd_match)
})

# --- error handling ------------------------------------------------------------

test_that("add_wikidata_matches tryCatch returns found=FALSE when search errors", {
  local_mocked_bindings(
    search_wikidata_one = function(...) stop("simulated network error"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "Any Name"), delay = 0)
  expect_false(result$wd_found)
  expect_false(result$wd_match)
  expect_true(is.na(result$wd_qid))
})

test_that("add_wikidata_matches forwards limit and type to search_wikidata_one", {
  received <- list()
  local_mocked_bindings(
    search_wikidata_one = function(query, lang = "en", limit = 5, type = "item") {
      received$limit <<- limit
      received$type  <<- type
      mock_not_found()
    },
    .package = "wikitools"
  )
  add_wikidata_matches(tibble(name = "Test"), limit = 3L, type = "property", delay = 0)
  expect_equal(received$limit, 3L)
  expect_equal(received$type, "property")
})

# --- .shortname and .langname -------------------------------------------------

test_that(".shortname = FALSE restores the wikidata_ prefix", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(tibble(name = "Tracy K. Smith"), delay = 0, .shortname = FALSE)

  old_cols <- c("wikidata_found", "wikidata_match", "wikidata_qid", "wikidata_label",
                "wikidata_description", "wikidata_alias_match", "wikidata_url")
  expect_true(all(old_cols %in% names(result)))
  expect_false(any(c("wd_found", "wd_match") %in% names(result)))
})

test_that(".langname = TRUE inserts the language code into wd_ column names", {
  local_mocked_bindings(
    search_wikidata_one = function(...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(
    tibble(name = "Tracy K. Smith"), lang = "en", delay = 0, .langname = TRUE
  )

  lang_cols <- c("wd_en_found", "wd_en_match", "wd_en_qid", "wd_en_label",
                 "wd_en_description", "wd_en_alias_match", "wd_en_url")
  expect_true(all(lang_cols %in% names(result)))
  expect_true(result$wd_en_found)
  expect_true(result$wd_en_match)
})

# --- Vector `lang` (multi-language single call) --------------------------------

test_that("a vector `lang` searches each language and appends columns for all of them", {
  local_mocked_bindings(
    search_wikidata_one = function(query, lang = "en", ...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(
    tibble(name = "Tracy K. Smith"), lang = c("en", "fr", "cs"), delay = 0
  )

  for (lg in c("en", "fr", "cs")) {
    expect_true(all(
      paste0("wd_", lg, "_", c("found", "match", "qid", "label", "description", "alias_match", "url")) %in%
        names(result)
    ))
  }
  expect_true(result$wd_en_found)
  expect_true(result$wd_fr_found)
  expect_true(result$wd_cs_found)
})

test_that("a vector `lang` forces .langname = TRUE even if the caller passes FALSE", {
  local_mocked_bindings(
    search_wikidata_one = function(query, lang = "en", ...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  expect_message(
    result <- add_wikidata_matches(
      tibble(name = "Tracy K. Smith"), lang = c("en", "fr"), delay = 0, .langname = FALSE
    ),
    "forcing"
  )
  expect_true(all(c("wd_en_found", "wd_fr_found") %in% names(result)))
})

test_that("a vector `lang` produces per-language results that can differ (found vs. not found)", {
  local_mocked_bindings(
    search_wikidata_one = function(query, lang = "en", ...) {
      if (lang == "en") mock_label_match("Q7831207", "Tracy K. Smith") else mock_not_found()
    },
    .package = "wikitools"
  )
  result <- add_wikidata_matches(
    tibble(name = "Tracy K. Smith"), lang = c("en", "cs"), delay = 0
  )

  expect_true(result$wd_en_found)
  expect_true(result$wd_en_match)
  expect_false(result$wd_cs_found)
  expect_false(result$wd_cs_match)
})

test_that("a vector `lang` respects .shortname = FALSE", {
  local_mocked_bindings(
    search_wikidata_one = function(query, lang = "en", ...) mock_label_match("Q7831207", "Tracy K. Smith"),
    .package = "wikitools"
  )
  result <- add_wikidata_matches(
    tibble(name = "Tracy K. Smith"), lang = c("en", "fr"), delay = 0, .shortname = FALSE
  )

  expect_true(all(c("wikidata_en_found", "wikidata_fr_found") %in% names(result)))
})
