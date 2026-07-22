# Tests for search_wikipedia_one() and uncovered branches of add_wikipedia_matches()
#
# search_wikipedia_one() is the internal HTTP helper that the existing
# test-add-wikipedia-matches.R mocks away entirely.  These tests exercise it
# directly (via httptest fixtures) and cover the error / edge-case paths in
# add_wikipedia_matches() that require the real implementation.
#
# Fixtures (tests/testthat/en.wikipedia.org/w/):
#   api.php-48c94f.json  — search for "Paul Rivet", 5 hits
#   api.php-72b8b1.json  — search for nonexistent query, 0 hits

library(httptest)

# ===========================================================================
# search_wikipedia_one() — via httptest
# ===========================================================================

with_mock_dir(".", {

  test_that("search_wikipedia_one returns found=TRUE and correct title for Paul Rivet", {
    result <- search_wikipedia_one("Paul Rivet")
    expect_true(result$found)
    expect_equal(result$title, "Paul Rivet")
  })

  test_that("search_wikipedia_one result has found, title, url, snippet fields", {
    result <- search_wikipedia_one("Paul Rivet")
    expect_named(result, c("found", "title", "url", "snippet"))
  })

  test_that("search_wikipedia_one url points to the en Wikipedia article", {
    result <- search_wikipedia_one("Paul Rivet")
    expect_match(result$url, "^https://en\\.wikipedia\\.org/wiki/")
    expect_true(grepl("Paul_Rivet", result$url, fixed = TRUE))
  })

  test_that("search_wikipedia_one snippet is a non-empty character string", {
    result <- search_wikipedia_one("Paul Rivet")
    expect_type(result$snippet, "character")
    expect_true(nzchar(result$snippet))
  })

  test_that("search_wikipedia_one returns found=FALSE for a query with no results", {
    result <- search_wikipedia_one("xkjzqmnoexist1234567890")
    expect_false(result$found)
    expect_true(is.na(result$title))
    expect_true(is.na(result$url))
    expect_true(is.na(result$snippet))
  })

})

# ===========================================================================
# search_wikipedia_one() — HTTP error path (mocked response)
# ===========================================================================

test_that("search_wikipedia_one returns found=FALSE on HTTP 400 response", {
  local_mocked_bindings(
    GET = function(...) structure(list(status_code = 400L), class = "response"),
    .package = "httr"
  )
  result <- search_wikipedia_one("anything")
  expect_false(result$found)
  expect_true(is.na(result$title))
  expect_true(is.na(result$url))
  expect_true(is.na(result$snippet))
})

test_that("search_wikipedia_one returns found=FALSE on HTTP 500 response", {
  local_mocked_bindings(
    GET = function(...) structure(list(status_code = 500L), class = "response"),
    .package = "httr"
  )
  result <- search_wikipedia_one("anything")
  expect_false(result$found)
})

# ===========================================================================
# search_wikipedia_one() — NA / blank query (no HTTP call made)
# ===========================================================================

test_that("search_wikipedia_one returns found=FALSE for NA query without API call", {
  expect_no_request({
    result <- search_wikipedia_one(NA_character_)
  })
  expect_false(result$found)
  expect_true(is.na(result$title))
})

test_that("search_wikipedia_one returns found=FALSE for blank query without API call", {
  expect_no_request({
    result <- search_wikipedia_one("   ")
  })
  expect_false(result$found)
})

# ===========================================================================
# search_wikipedia_one() — lang parameter forwarded to URL
# ===========================================================================

test_that("search_wikipedia_one constructs URL with the correct lang subdomain", {
  # Verify that the lang argument controls which Wikipedia edition is queried.
  # We check this by intercepting the GET call and inspecting the URL it received.
  captured_url <- NULL
  local_mocked_bindings(
    GET = function(url, ...) {
      captured_url <<- url
      structure(list(status_code = 400L), class = "response")
    },
    .package = "httr"
  )
  search_wikipedia_one("test query", lang = "fr")
  expect_true(grepl("fr\\.wikipedia\\.org", captured_url))
})

# ===========================================================================
# add_wikipedia_matches() — uncovered branches
# ===========================================================================

test_that("add_wikipedia_matches returns data.frame (not tibble) for data.frame input", {
  df <- data.frame(name = "Paul Rivet", stringsAsFactors = FALSE)
  local_mocked_bindings(
    search_wikipedia_one = function(...) list(found = TRUE, title = "Paul Rivet",
                                             url = "https://en.wikipedia.org/wiki/Paul_Rivet",
                                             snippet = "French ethnologist"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(df, delay = 0)
  expect_s3_class(result, "data.frame")
  expect_false(inherits(result, "tbl_df"))
})

test_that("add_wikipedia_matches tryCatch returns found=FALSE when search errors", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) stop("simulated network error"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble::tibble(name = "Any Name"), delay = 0)
  expect_false(result$wikipedia_found)
  expect_false(result$wikipedia_match)
  expect_true(is.na(result$wikipedia_title))
})

test_that("add_wikipedia_matches forwards limit to search_wikipedia_one", {
  received_limit <- NULL
  local_mocked_bindings(
    search_wikipedia_one = function(query, lang = "en", limit = 5) {
      received_limit <<- limit
      list(found = FALSE, title = NA_character_,
           url = NA_character_, snippet = NA_character_)
    },
    .package = "wikitools"
  )
  add_wikipedia_matches(tibble::tibble(name = "Test"), limit = 3L, delay = 0)
  expect_equal(received_limit, 3L)
})

test_that("add_wikipedia_matches wikipedia_snippet is populated from search result", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) list(found = TRUE, title = "Paul Rivet",
                                             url = "https://en.wikipedia.org/wiki/Paul_Rivet",
                                             snippet = "French ethnologist"),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble::tibble(name = "Paul Rivet"), delay = 0)
  expect_equal(result$wikipedia_snippet, "French ethnologist")
})

test_that("add_wikipedia_matches wikipedia_snippet is NA when found=FALSE", {
  local_mocked_bindings(
    search_wikipedia_one = function(...) list(found = FALSE, title = NA_character_,
                                             url = NA_character_, snippet = NA_character_),
    .package = "wikitools"
  )
  result <- add_wikipedia_matches(tibble::tibble(name = "Unknown Person"), delay = 0)
  expect_true(is.na(result$wikipedia_snippet))
})
