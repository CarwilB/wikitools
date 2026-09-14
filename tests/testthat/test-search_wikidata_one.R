# Tests for search_wikidata_one() and uncovered branches of add_wikidata_matches()
#
# search_wikidata_one() is the internal HTTP helper that test-add-wikidata-matches.R
# mocks away entirely. These tests exercise it directly (via httptest fixtures) and
# cover the error / edge-case paths in add_wikidata_matches() that require the real
# implementation.
#
# Fixtures (tests/testthat/www.wikidata.org/w/):
#   api.php-30653c.json — wbsearchentities search for "Paul Rivet" (label match, 5 hits)
#   api.php-d7bd44.json — wbsearchentities search for "NYC" (alias match, 5 hits)
#   api.php-cb3cf7.json — wbsearchentities search for nonexistent query, 0 hits

library(httptest)

# ===========================================================================
# search_wikidata_one() — via httptest
# ===========================================================================

with_mock_dir(".", {

  test_that("search_wikidata_one returns found=TRUE and correct qid/label for a label match", {
    result <- search_wikidata_one("Paul Rivet")
    expect_true(result$found)
    expect_equal(result$qid, "Q694431")
    expect_equal(result$label, "Paul Rivet")
  })

  test_that("search_wikidata_one result has the expected named fields", {
    result <- search_wikidata_one("Paul Rivet")
    expect_named(result, c("found", "qid", "label", "description",
                            "alias_match", "match_text", "url"))
  })

  test_that("search_wikidata_one url points to the Wikidata item", {
    result <- search_wikidata_one("Paul Rivet")
    expect_match(result$url, "^https://www\\.wikidata\\.org/wiki/Q694431$")
  })

  test_that("search_wikidata_one description is a non-empty character string for a label match", {
    result <- search_wikidata_one("Paul Rivet")
    expect_type(result$description, "character")
    expect_true(nzchar(result$description))
  })

  test_that("search_wikidata_one alias_match is FALSE for a label match", {
    result <- search_wikidata_one("Paul Rivet")
    expect_false(result$alias_match)
    expect_equal(result$match_text, "Paul Rivet")
  })

  test_that("search_wikidata_one alias_match is TRUE and label differs from query for an alias match", {
    result <- search_wikidata_one("NYC")
    expect_true(result$found)
    expect_true(result$alias_match)
    expect_equal(result$match_text, "NYC")
    expect_equal(result$label, "New York City")
    expect_false(identical(tolower(result$label), tolower("NYC")))
  })

  test_that("search_wikidata_one returns found=FALSE for a query with no results", {
    result <- search_wikidata_one("xkjzqmnoexist1234567890")
    expect_false(result$found)
    expect_true(is.na(result$qid))
    expect_true(is.na(result$label))
    expect_true(is.na(result$description))
    expect_true(is.na(result$alias_match))
    expect_true(is.na(result$match_text))
    expect_true(is.na(result$url))
  })

})

# ===========================================================================
# search_wikidata_one() — HTTP error path (mocked response)
# ===========================================================================

test_that("search_wikidata_one returns found=FALSE on HTTP 400 response", {
  local_mocked_bindings(
    GET = function(...) structure(list(status_code = 400L), class = "response"),
    .package = "httr"
  )
  result <- search_wikidata_one("anything")
  expect_false(result$found)
  expect_true(is.na(result$qid))
  expect_true(is.na(result$label))
  expect_true(is.na(result$url))
})

test_that("search_wikidata_one returns found=FALSE on HTTP 500 response", {
  local_mocked_bindings(
    GET = function(...) structure(list(status_code = 500L), class = "response"),
    .package = "httr"
  )
  result <- search_wikidata_one("anything")
  expect_false(result$found)
})

# ===========================================================================
# search_wikidata_one() — NA / blank query (no HTTP call made)
# ===========================================================================

test_that("search_wikidata_one returns found=FALSE for NA query without API call", {
  expect_no_request({
    result <- search_wikidata_one(NA_character_)
  })
  expect_false(result$found)
  expect_true(is.na(result$qid))
})

test_that("search_wikidata_one returns found=FALSE for blank query without API call", {
  expect_no_request({
    result <- search_wikidata_one("   ")
  })
  expect_false(result$found)
})

# ===========================================================================
# search_wikidata_one() — lang and type parameters forwarded to the request
# ===========================================================================

test_that("search_wikidata_one constructs a request with the correct language parameter", {
  captured_query <- NULL
  local_mocked_bindings(
    GET = function(url, query, ...) {
      captured_query <<- query
      structure(list(status_code = 400L), class = "response")
    },
    .package = "httr"
  )
  search_wikidata_one("test query", lang = "fr")
  expect_equal(captured_query$language, "fr")
  expect_equal(captured_query$uselang, "fr")
})

test_that("search_wikidata_one forwards the type parameter", {
  captured_query <- NULL
  local_mocked_bindings(
    GET = function(url, query, ...) {
      captured_query <<- query
      structure(list(status_code = 400L), class = "response")
    },
    .package = "httr"
  )
  search_wikidata_one("test query", type = "property")
  expect_equal(captured_query$type, "property")
})

test_that("search_wikidata_one forwards the limit parameter", {
  captured_query <- NULL
  local_mocked_bindings(
    GET = function(url, query, ...) {
      captured_query <<- query
      structure(list(status_code = 400L), class = "response")
    },
    .package = "httr"
  )
  search_wikidata_one("test query", limit = 17L)
  expect_equal(captured_query$limit, 17L)
})

# ===========================================================================
# add_wikidata_matches() — integration with real search_wikidata_one() (via fixtures)
# ===========================================================================

with_mock_dir(".", {

  test_that("add_wikidata_matches integrates end-to-end with a label-match fixture", {
    result <- add_wikidata_matches(tibble::tibble(name = "Paul Rivet"), delay = 0)
    expect_true(result$wd_found)
    expect_true(result$wd_match)
    expect_equal(result$wd_qid, "Q694431")
    expect_false(result$wd_alias_match)
  })

  test_that("add_wikidata_matches integrates end-to-end with an alias-match fixture", {
    result <- add_wikidata_matches(tibble::tibble(name = "NYC"), delay = 0)
    expect_true(result$wd_found)
    expect_true(result$wd_match)
    expect_true(result$wd_alias_match)
    expect_equal(result$wd_label, "New York City")
  })

  test_that("add_wikidata_matches integrates end-to-end with a no-results fixture", {
    result <- add_wikidata_matches(tibble::tibble(name = "xkjzqmnoexist1234567890"), delay = 0)
    expect_false(result$wd_found)
    expect_false(result$wd_match)
  })

})
