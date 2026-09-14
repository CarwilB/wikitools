# Tests for find_wikipedia_matches() and search_wikipedia_all()
#
# search_wikipedia_all() is exercised directly via the existing httptest
# fixtures captured for search_wikipedia_one (tests/testthat/en.wikipedia.org/w/):
#   api.php-48c94f.json  — search for "Paul Rivet", 5 hits
#   api.php-72b8b1.json  — search for nonexistent query, 0 hits
# Both fixtures were captured with srlimit=5, so tests pass limit = 5 to
# match the recorded request URLs.
#
# find_wikipedia_matches() tests mock search_wikipedia_all() entirely.

library(httptest)

# ===========================================================================
# search_wikipedia_all() — via httptest
# ===========================================================================

with_mock_dir(".", {

  test_that("search_wikipedia_all returns all hits for Paul Rivet", {
    result <- search_wikipedia_all("Paul Rivet", limit = 5)
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 5)
  })

  test_that("search_wikipedia_all result has title, url, snippet columns", {
    result <- search_wikipedia_all("Paul Rivet", limit = 5)
    expect_named(result, c("title", "url", "snippet"))
  })

  test_that("search_wikipedia_all top hit is Paul Rivet", {
    result <- search_wikipedia_all("Paul Rivet", limit = 5)
    expect_equal(result$title[[1]], "Paul Rivet")
  })

  test_that("search_wikipedia_all urls point to en Wikipedia articles", {
    result <- search_wikipedia_all("Paul Rivet", limit = 5)
    expect_true(all(grepl("^https://en\\.wikipedia\\.org/wiki/", result$url)))
    expect_true(grepl("Paul_Rivet", result$url[[1]], fixed = TRUE))
  })

  test_that("search_wikipedia_all returns zero rows for a query with no results", {
    result <- search_wikipedia_all("xkjzqmnoexist1234567890", limit = 5)
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 0)
    expect_named(result, c("title", "url", "snippet"))
  })

})

# ===========================================================================
# search_wikipedia_all() — error and edge-case paths
# ===========================================================================

test_that("search_wikipedia_all returns zero rows on HTTP 400 response", {
  local_mocked_bindings(
    GET = function(...) structure(list(status_code = 400L), class = "response"),
    status_code = function(resp, ...) resp$status_code,
    .package = "httr"
  )
  result <- search_wikipedia_all("Paul Rivet")
  expect_equal(nrow(result), 0)
})

test_that("search_wikipedia_all returns zero rows when GET throws an error", {
  local_mocked_bindings(
    GET = function(...) stop("connection failed"),
    .package = "httr"
  )
  result <- search_wikipedia_all("Paul Rivet")
  expect_equal(nrow(result), 0)
})

test_that("search_wikipedia_all returns zero rows for blank and NA queries", {
  expect_equal(nrow(search_wikipedia_all("")), 0)
  expect_equal(nrow(search_wikipedia_all("   ")), 0)
  expect_equal(nrow(search_wikipedia_all(NA_character_)), 0)
})

# ===========================================================================
# find_wikipedia_matches() — with mocked search_wikipedia_all()
# ===========================================================================

mock_hits <- function(...) {
  tibble::tibble(
    title = c("Revolver", "Revolver (Beatles album)", "Revolver (disambiguation)"),
    url = paste0("https://en.wikipedia.org/wiki/",
                 gsub(" ", "_", c("Revolver", "Revolver (Beatles album)",
                                  "Revolver (disambiguation)"))),
    snippet = c("A revolver is...", "Album by the Beatles...", "Revolver may refer to...")
  )
}

test_that("find_wikipedia_matches returns one row per hit with ranks", {
  local_mocked_bindings(search_wikipedia_all = mock_hits)
  result <- find_wikipedia_matches("Revolver", delay = 0)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3)
  expect_equal(result$rank, 1:3)
  expect_named(result, c("query", "rank", "match", "title", "url", "snippet"))
})

test_that("find_wikipedia_matches flags exact matches per hit", {
  local_mocked_bindings(search_wikipedia_all = mock_hits)
  result <- find_wikipedia_matches("Revolver", delay = 0)
  expect_equal(result$match, c(TRUE, FALSE, FALSE))
})

test_that("find_wikipedia_matches match is case- and whitespace-insensitive", {
  local_mocked_bindings(search_wikipedia_all = mock_hits)
  result <- find_wikipedia_matches("  revolver ", delay = 0)
  expect_true(result$match[[1]])
})

test_that("find_wikipedia_matches repeats hits for each query", {
  local_mocked_bindings(search_wikipedia_all = mock_hits)
  result <- find_wikipedia_matches(c("Revolver", "Abbey Road"), delay = 0)
  expect_equal(nrow(result), 6)
  expect_equal(result$query, rep(c("Revolver", "Abbey Road"), each = 3))
})

test_that("find_wikipedia_matches keeps a placeholder row when no hits", {
  local_mocked_bindings(
    search_wikipedia_all = function(query, ...) {
      if (query == "zzznothing") {
        tibble::tibble(title = character(), url = character(), snippet = character())
      } else {
        mock_hits()
      }
    }
  )
  result <- find_wikipedia_matches(c("Revolver", "zzznothing"), delay = 0)
  expect_equal(nrow(result), 4) # 3 hits + 1 placeholder
  placeholder <- result[result$query == "zzznothing", ]
  expect_equal(nrow(placeholder), 1)
  expect_true(is.na(placeholder$rank))
  expect_true(is.na(placeholder$match))
  expect_true(is.na(placeholder$title))
})

test_that("find_wikipedia_matches accepts a data frame and name_col", {
  local_mocked_bindings(search_wikipedia_all = mock_hits)
  df <- tibble::tibble(album = c("Revolver", "Abbey Road"))
  result <- find_wikipedia_matches(df, name_col = "album", delay = 0)
  expect_equal(result$query, rep(c("Revolver", "Abbey Road"), each = 3))
})

test_that("find_wikipedia_matches forwards n and lang to search_wikipedia_all", {
  seen <- new.env()
  local_mocked_bindings(
    search_wikipedia_all = function(query, lang, limit) {
      seen$lang <- lang
      seen$limit <- limit
      mock_hits()
    }
  )
  find_wikipedia_matches("Revolver", n = 10, lang = "cs", delay = 0)
  expect_equal(seen$lang, "cs")
  expect_equal(seen$limit, 10)
})

test_that("find_wikipedia_matches errors on missing name_col", {
  expect_error(
    find_wikipedia_matches(tibble::tibble(x = "a"), name_col = "album"),
    "name_col"
  )
})
