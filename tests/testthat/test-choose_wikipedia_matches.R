# Tests for choose_wikipedia_matches() and get_short_descriptions()
#
# get_short_descriptions() is exercised via an httptest fixture captured from
# the live en Wikipedia API (tests/testthat/en.wikipedia.org/w/):
#   api.php-d3b04d.json — short descriptions for "Revolver (Beatles album)",
#                         "Revolver" (the firearm article), and
#                         "Revolver (disambiguation)"
#
# choose_wikipedia_matches() tests mock search_wikipedia_all(),
# get_short_descriptions(), utils::menu(), and base::interactive() (tests
# run non-interactively).

library(httptest)

# ===========================================================================
# get_short_descriptions() — via httptest
# ===========================================================================

with_mock_dir(".", {

  test_that("get_short_descriptions returns descriptions for the Revolver titles", {
    result <- get_short_descriptions(
      c("Revolver (Beatles album)", "Revolver", "Revolver (disambiguation)")
    )
    expect_type(result, "character")
    expect_length(result, 3)
    expect_equal(
      unname(result[["Revolver (Beatles album)"]]),
      "1966 studio album by the Beatles"
    )
    # "Revolver" is the firearm article, not the album — descriptions
    # distinguish them
    expect_match(unname(result[["Revolver"]]), "[Ff]irearm")
  })

  test_that("get_short_descriptions result is named by title", {
    result <- get_short_descriptions(c("Revolver (Beatles album)", "Revolver"))
    expect_equal(names(result), c("Revolver (Beatles album)", "Revolver"))
  })

})

# ===========================================================================
# get_short_descriptions() — error and edge-case paths
# ===========================================================================

test_that("get_short_descriptions returns empty vector for empty/NA input", {
  expect_length(get_short_descriptions(character()), 0)
  expect_length(get_short_descriptions(NA_character_), 0)
})

test_that("get_short_descriptions returns NA descriptions on HTTP error", {
  local_mocked_bindings(
    GET = function(...) structure(list(status_code = 400L), class = "response"),
    status_code = function(resp, ...) resp$status_code,
    .package = "httr"
  )
  result <- get_short_descriptions("Revolver")
  expect_named(result, "Revolver")
  expect_true(is.na(result[["Revolver"]]))
})

test_that("get_short_descriptions returns NA descriptions when GET errors", {
  local_mocked_bindings(
    GET = function(...) stop("connection failed"),
    .package = "httr"
  )
  result <- get_short_descriptions("Revolver")
  expect_true(is.na(result[["Revolver"]]))
})

# ===========================================================================
# choose_wikipedia_matches() — fully mocked
# ===========================================================================

mock_choose_hits <- function(...) {
  tibble::tibble(
    title = c("Revolver", "Revolver (Beatles album)", "Revolver (disambiguation)"),
    url = paste0(
      "https://en.wikipedia.org/wiki/",
      gsub(" ", "_", c("Revolver", "Revolver (Beatles album)",
                       "Revolver (disambiguation)"))
    ),
    snippet = c("A revolver is...", "Album by the Beatles...", "Revolver may refer to...")
  )
}

mock_choose_descriptions <- function(titles, lang = "en") {
  stats::setNames(
    c("Firearm with a cylinder holding cartridges",
      "1966 studio album by the Beatles",
      "Topics referred to by the same term")[seq_along(titles)],
    titles
  )
}

mock_choose <- function(picks) {
  # Returns an environment holding call info and a menu() replacement that
  # pops from `picks` on successive calls.
  calls <- new.env()
  calls$n <- 0L
  calls$titles <- character()
  calls$choices <- list()
  menu_fn <- function(choices, title = NULL, graphics = FALSE) {
    calls$n <- calls$n + 1L
    calls$titles <- c(calls$titles, title)
    calls$choices[[calls$n]] <- choices
    picks[[min(calls$n, length(picks))]]
  }
  list(calls = calls, menu_fn = menu_fn)
}

# `.env = caller_env()` ties mock teardown to the calling test_that() block:
# registered here but active for exactly one test (no leakage across tests).
setup_choose_mocks <- function(menu_fn, .env = rlang::caller_env()) {
  local_mocked_bindings(search_wikipedia_all = mock_choose_hits, .env = .env)
  local_mocked_bindings(get_short_descriptions = mock_choose_descriptions, .env = .env)
  local_mocked_bindings(is_interactive = function() TRUE, .env = .env)
  local_mocked_bindings(menu = menu_fn, .package = "utils", .env = .env)
  invisible(NULL)
}

test_that("choose_wikipedia_matches errors in non-interactive sessions", {
  # test_file() may itself run inside an interactive session, so force
  # the interactivity check to FALSE here.
  local_mocked_bindings(is_interactive = function() FALSE)
  expect_error(
    choose_wikipedia_matches("Revolver"),
    "interactive"
  )
})

test_that("choose_wikipedia_matches returns the picked hit", {
  m <- mock_choose(list(2L)) # pick "Revolver (Beatles album)"
  setup_choose_mocks(m$menu_fn)
  result <- choose_wikipedia_matches("Revolver", delay = 0)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 1)
  expect_named(result, c("query", "found", "chosen", "rank", "title", "url",
                         "description"))
  expect_true(result$found)
  expect_true(result$chosen)
  expect_equal(result$rank, 2L)
  expect_equal(result$title, "Revolver (Beatles album)")
  expect_equal(result$description, "1966 studio album by the Beatles")
  expect_match(result$url, "Revolver_\\(Beatles_album\\)")
})

test_that("choose_wikipedia_matches offers one choice per hit plus skip", {
  m <- mock_choose(list(1L))
  setup_choose_mocks(m$menu_fn)
  choose_wikipedia_matches("Revolver", delay = 0)

  choices <- m$calls$choices[[1]]
  expect_length(choices, 4) # 3 hits + "None of these"
  expect_match(choices[[4]], "None of these")
})

test_that("choose_wikipedia_matches menu choices include descriptions", {
  m <- mock_choose(list(1L))
  setup_choose_mocks(m$menu_fn)
  choose_wikipedia_matches("Revolver", delay = 0)

  choices <- m$calls$choices[[1]]
  expect_match(choices[[1]], "Revolver — Firearm")
  expect_match(choices[[2]], "Revolver \\(Beatles album\\) — 1966 studio album")
  expect_match(m$calls$titles[[1]], "Revolver")
})

test_that("choose_wikipedia_matches records skip when user picks 0", {
  m <- mock_choose(list(0L))
  setup_choose_mocks(m$menu_fn)
  result <- choose_wikipedia_matches("Revolver", delay = 0)

  expect_true(result$found)
  expect_false(result$chosen)
  expect_true(is.na(result$title))
  expect_true(is.na(result$rank))
})

test_that("choose_wikipedia_matches records skip when user picks 'None of these'", {
  m <- mock_choose(list(4L)) # the "None of these" entry
  setup_choose_mocks(m$menu_fn)
  result <- choose_wikipedia_matches("Revolver", delay = 0)

  expect_true(result$found)
  expect_false(result$chosen)
})

test_that("choose_wikipedia_matches handles queries with no hits", {
  m <- mock_choose(list(1L))
  local_mocked_bindings(
    search_wikipedia_all = function(query, ...) {
      if (query == "zzznothing") {
        tibble::tibble(title = character(), url = character(), snippet = character())
      } else {
        mock_choose_hits()
      }
    }
  )
  local_mocked_bindings(get_short_descriptions = mock_choose_descriptions)
  local_mocked_bindings(is_interactive = function() TRUE)
  local_mocked_bindings(menu = m$menu_fn, .package = "utils")

  expect_message(
    result <- choose_wikipedia_matches(c("Revolver", "zzznothing"), delay = 0),
    "No Wikipedia results"
  )
  expect_equal(nrow(result), 2)
  expect_true(result$chosen[[1]])
  expect_false(result$found[[2]])
  expect_false(result$chosen[[2]])
  expect_equal(m$calls$n, 1L) # menu only shown for the query with hits
})

test_that("choose_wikipedia_matches handles multiple queries with different picks", {
  m <- mock_choose(list(2L, 0L))
  setup_choose_mocks(m$menu_fn)
  result <- choose_wikipedia_matches(c("Revolver", "Let It Be"), delay = 0)

  expect_equal(nrow(result), 2)
  expect_equal(result$query, c("Revolver", "Let It Be"))
  expect_true(result$chosen[[1]])
  expect_false(result$chosen[[2]])
  expect_equal(m$calls$n, 2L)
})

test_that("choose_wikipedia_matches accepts a data frame and name_col", {
  m <- mock_choose(list(1L))
  setup_choose_mocks(m$menu_fn)
  df <- tibble::tibble(album = "Revolver")
  result <- choose_wikipedia_matches(df, name_col = "album", delay = 0)
  expect_equal(result$query, "Revolver")
  expect_equal(result$title, "Revolver")
})
