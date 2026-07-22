# Tests for wikiblame.R
#
# Article: Paul Rivet (en.wikipedia.org/wiki/Paul_Rivet)
#   121 revisions; no pagination. First revision 54062200 (2006-05-19).
#
# Fixtures (httptest, tests/testthat/en.wikipedia.org/w/):
#   api.php-a68424.json  — revision history map (rvprop=ids|timestamp|user)
#   api.php-89979b.json  — current wikitext  (titles=Paul Rivet, rvprop=content)
#   api.php-ac7085.json  — first-revision wikitext (revids=54062200, rvprop=content)
#
# Binary-search functions are tested with a synthetic 7-revision history and
# local_mocked_bindings(), so no additional API fixtures are required.

library(httptest)

# ---------------------------------------------------------------------------
# Synthetic fixtures reused by binary-search tests
# ---------------------------------------------------------------------------

# A minimal 7-entry history covering Editor1 (revid 1001) … Editor7 (revid 1007).
.fake_history <- data.frame(
  revid     = 1001L:1007L,
  timestamp = paste0(2010:2016, "-06-01T00:00:00Z"),
  user      = paste0("Editor", 1:7),
  stringsAsFactors = FALSE
)

# Three sentences with known insertion points:
#   ALPHA — present from the very first revision (revid 1001)
#   BETA  — first added at revid 1004 (Editor4)
#   GAMMA — first added at revid 1006 (Editor6)
#   DELTA — never present in any revision
.ALPHA <- "was an ethnologist known for his work"
.BETA  <- "He married Mercedes Andrade Chiriboga"
.GAMMA <- "His birthplace in Wasigny was remarkable"
.DELTA <- "this sentence does not appear in any revision"

# Mock for get_revision_text_safe: returns deterministic wikitext based on revid
.mock_text <- function(revid, lang = "en") {
  base  <- paste0("Paul Rivet ", .ALPHA, ".")
  beta  <- if (revid >= 1004L) paste0(" ", .BETA, ".") else ""
  gamma <- if (revid >= 1006L) paste0(" ", .GAMMA, ".") else ""
  paste0(base, beta, gamma)
}

# ===========================================================================
# get_revision_history_map() — httptest fixture
# ===========================================================================

with_mock_dir(".", {

  test_that("get_revision_history_map returns a data.frame", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_s3_class(hist, "data.frame")
  })

  test_that("get_revision_history_map has revid, timestamp, user columns", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_named(hist, c("revid", "timestamp", "user"))
  })

  test_that("get_revision_history_map returns 121 revisions for Paul Rivet", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_equal(nrow(hist), 121L)
  })

  test_that("get_revision_history_map rows are sorted oldest-first", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_equal(hist$timestamp, sort(hist$timestamp))
  })

  test_that("oldest revision is 54062200 (2006-05-19)", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_equal(hist$revid[1], 54062200L)
    expect_true(startsWith(hist$timestamp[1], "2006-05-19"))
  })

  test_that("most recent revision is 1355809380 (2026-05-24)", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_equal(tail(hist$revid, 1), 1355809380L)
    expect_true(startsWith(tail(hist$timestamp, 1), "2026-05-24"))
  })

  test_that("revid column is numeric", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_true(is.numeric(hist$revid))
  })

  test_that("user column is character", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_type(hist$user, "character")
  })

  test_that("timestamp column matches ISO 8601 format", {
    hist <- suppressMessages(get_revision_history_map("Paul Rivet"))
    expect_true(all(grepl("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z$",
                          hist$timestamp)))
  })

})

# ===========================================================================
# get_revision_text_safe() — httptest fixture for first revision
# ===========================================================================

with_mock_dir(".", {

  test_that("get_revision_text_safe returns a character string", {
    result <- get_revision_text_safe(54062200L)
    expect_type(result, "character")
    expect_length(result, 1L)
  })

  test_that("first revision contains 'Musée de l'Homme'", {
    result <- get_revision_text_safe(54062200L)
    expect_true(grepl("Mus\u00e9e de l'Homme", result, fixed = TRUE))
  })

  test_that("first revision contains 'Melanesia'", {
    result <- get_revision_text_safe(54062200L)
    expect_true(grepl("Melanesia", result, fixed = TRUE))
  })

  test_that("first revision does not contain 'Mercedes' (added later)", {
    result <- get_revision_text_safe(54062200L)
    expect_false(grepl("Mercedes", result, fixed = TRUE))
  })

  test_that("first revision does not contain 'Wasigny' (added later)", {
    result <- get_revision_text_safe(54062200L)
    expect_false(grepl("Wasigny", result, fixed = TRUE))
  })

})

# ===========================================================================
# find_sentence_insertion() — synthetic history + mocked text fetch
# ===========================================================================

test_that("find_sentence_insertion errors on empty history_map", {
  empty_map <- data.frame(revid = integer(), timestamp = character(),
                          user = character(), stringsAsFactors = FALSE)
  expect_error(
    suppressMessages(
      find_sentence_insertion("Paul Rivet", .ALPHA, history_map = empty_map)
    ),
    "No revisions found"
  )
})

test_that("find_sentence_insertion finds sentence present in every revision (revid 1001)", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    find_sentence_insertion("Paul Rivet", .ALPHA, history_map = .fake_history)
  )
  expect_false(is.null(result))
  expect_equal(result$revid, 1001L)
  expect_equal(result$user, "Editor1")
})

test_that("find_sentence_insertion finds mid-history insertion (revid 1004)", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    find_sentence_insertion("Paul Rivet", .BETA, history_map = .fake_history)
  )
  expect_equal(result$revid, 1004L)
  expect_equal(result$user, "Editor4")
})

test_that("find_sentence_insertion finds late-history insertion (revid 1006)", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    find_sentence_insertion("Paul Rivet", .GAMMA, history_map = .fake_history)
  )
  expect_equal(result$revid, 1006L)
  expect_equal(result$user, "Editor6")
})

test_that("find_sentence_insertion returns NULL when sentence not found", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    find_sentence_insertion("Paul Rivet", .DELTA, history_map = .fake_history)
  )
  expect_null(result)
})

test_that("find_sentence_insertion result is a one-row data.frame", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    find_sentence_insertion("Paul Rivet", .BETA, history_map = .fake_history)
  )
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
  expect_true(all(c("revid", "timestamp", "user") %in% names(result)))
})

test_that("find_sentence_insertion fetches history when history_map is NULL", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    find_sentence_insertion("Paul Rivet", .BETA)
  )
  expect_equal(result$revid, 1004L)
})

test_that("find_sentence_insertion timestamp format is ISO 8601", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    find_sentence_insertion("Paul Rivet", .BETA, history_map = .fake_history)
  )
  expect_match(result$timestamp, "^\\d{4}-\\d{2}-\\d{2}T")
})

# ===========================================================================
# .find_sentence_with_map() — internal helper
# ===========================================================================

test_that(".find_sentence_with_map returns the correct row when found", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- wikitools:::.find_sentence_with_map(.BETA, "Paul Rivet", .fake_history)
  expect_equal(result$revid, 1004L)
  expect_equal(result$user, "Editor4")
})

test_that(".find_sentence_with_map returns NA row when sentence absent", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- wikitools:::.find_sentence_with_map(.DELTA, "Paul Rivet", .fake_history)
  expect_true(is.na(result$revid))
  expect_true(is.na(result$user))
  expect_true(is.na(result$timestamp))
})

test_that(".find_sentence_with_map result has revid, timestamp, user columns", {
  local_mocked_bindings(
    get_revision_text_safe = .mock_text,
    .package = "wikitools"
  )
  result <- wikitools:::.find_sentence_with_map(.ALPHA, "Paul Rivet", .fake_history)
  expect_named(result, c("revid", "timestamp", "user"))
})

# ===========================================================================
# track_wikipedia_sentences() — synthetic history + mocked fetchers
# ===========================================================================

test_that("track_wikipedia_sentences returns a data.frame", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    track_wikipedia_sentences("Paul Rivet", c(.ALPHA, .BETA))
  )
  expect_s3_class(result, "data.frame")
})

test_that("track_wikipedia_sentences has expected column names", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    track_wikipedia_sentences("Paul Rivet", c(.ALPHA, .BETA))
  )
  expect_named(result, c("original_sentence", "added_by", "date_added", "revision_id"))
})

test_that("track_wikipedia_sentences returns one row per input sentence", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  sentences <- c(.ALPHA, .BETA, .GAMMA)
  result <- suppressMessages(
    track_wikipedia_sentences("Paul Rivet", sentences)
  )
  expect_equal(nrow(result), 3L)
})

test_that("track_wikipedia_sentences preserves original_sentence order", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  sentences <- c(.ALPHA, .BETA, .GAMMA)
  result <- suppressMessages(
    track_wikipedia_sentences("Paul Rivet", sentences)
  )
  expect_equal(result$original_sentence, sentences)
})

test_that("track_wikipedia_sentences finds all three insertion points", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    track_wikipedia_sentences("Paul Rivet", c(.ALPHA, .BETA, .GAMMA))
  )
  expect_equal(result$revision_id[1], 1001L)
  expect_equal(result$revision_id[2], 1004L)
  expect_equal(result$revision_id[3], 1006L)
  expect_equal(result$added_by[1], "Editor1")
  expect_equal(result$added_by[2], "Editor4")
  expect_equal(result$added_by[3], "Editor6")
})

test_that("track_wikipedia_sentences returns NA for unfound sentence", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    track_wikipedia_sentences("Paul Rivet", c(.BETA, .DELTA))
  )
  expect_equal(result$revision_id[1], 1004L)
  expect_true(is.na(result$revision_id[2]))
  expect_true(is.na(result$added_by[2]))
})

test_that("track_wikipedia_sentences date_added is ISO 8601 for found sentences", {
  local_mocked_bindings(
    get_revision_history_map = function(...) .fake_history,
    get_revision_text_safe   = .mock_text,
    .package = "wikitools"
  )
  result <- suppressMessages(
    track_wikipedia_sentences("Paul Rivet", c(.BETA))
  )
  expect_match(result$date_added[1], "^\\d{4}-\\d{2}-\\d{2}T")
})
