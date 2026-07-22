# Tests for get_wikidata_instances.R
#
# Covers: .build_sparql_query(), .extract_instance_or_subclass(),
#         simplify_list_columns(), .parse_entity(), get_wikidata_instances(),
#         resume_get_wikidata_instances(), object_type validation.
#
# API fixtures (httptest, tests/testthat/):
#   query.wikidata.org/sparql-7ae1e7.R        — SPARQL for Q978708 (P39, limit 1000)
#   www.wikidata.org/w/api.php-bd18af.json    — wbgetentities for 6 East Timor PMs

library(httptest)

# ---------------------------------------------------------------------------
# .build_sparql_query() — pure function
# ---------------------------------------------------------------------------

test_that(".build_sparql_query includes the correct property and class QID", {
  q <- wikitools:::.build_sparql_query("Q978708", property_id = "P31")
  expect_true(grepl("wdt:P31",   q, fixed = TRUE))
  expect_true(grepl("wd:Q978708", q, fixed = TRUE))
})

test_that(".build_sparql_query uses P279 for subclass queries", {
  q <- wikitools:::.build_sparql_query("Q5", property_id = "P279")
  expect_true(grepl("wdt:P279", q, fixed = TRUE))
})

test_that(".build_sparql_query uses P39 for position_held queries", {
  q <- wikitools:::.build_sparql_query("Q978708", property_id = "P39")
  expect_true(grepl("wdt:P39", q, fixed = TRUE))
})

test_that(".build_sparql_query inserts LIMIT correctly", {
  q <- wikitools:::.build_sparql_query("Q5", limit = 250)
  expect_true(grepl("LIMIT 250", q, fixed = TRUE))
})

test_that(".build_sparql_query adds country triple when country is supplied", {
  q <- wikitools:::.build_sparql_query("Q5", country = "Q750")
  expect_true(grepl("wdt:P17", q, fixed = TRUE))
  expect_true(grepl("wd:Q750", q, fixed = TRUE))
})

test_that(".build_sparql_query omits country triple when country is NULL", {
  q <- wikitools:::.build_sparql_query("Q5", country = NULL)
  expect_false(grepl("wdt:P17", q, fixed = TRUE))
})

test_that(".build_sparql_query rejects a non-property-format property_id", {
  expect_error(
    wikitools:::.build_sparql_query("Q5", property_id = "not_a_property"),
    "property_id"
  )
})

# ---------------------------------------------------------------------------
# .extract_instance_or_subclass() — pure function
# ---------------------------------------------------------------------------

test_that(".extract_instance_or_subclass returns empty character when no claims", {
  entity_no_claims <- list()
  result <- wikitools:::.extract_instance_or_subclass(entity_no_claims)
  expect_equal(result, character(0))
})

test_that(".extract_instance_or_subclass returns empty character when property absent", {
  entity <- list(claims = list(P279 = data.frame()))
  result <- wikitools:::.extract_instance_or_subclass(entity, property_id = "P31")
  expect_equal(result, character(0))
})

# ---------------------------------------------------------------------------
# simplify_list_columns() — pure function
# ---------------------------------------------------------------------------

test_that("simplify_list_columns converts single-value list column to character", {
  df <- tibble::tibble(x = list("a", "b", "c"))
  out <- simplify_list_columns(df)
  expect_type(out$x, "character")
  expect_equal(out$x, c("a", "b", "c"))
})

test_that("simplify_list_columns converts empty-list elements to NA_character_", {
  df <- tibble::tibble(x = list("a", character(0), "c"))
  out <- simplify_list_columns(df)
  expect_type(out$x, "character")
  expect_true(is.na(out$x[2]))
})

test_that("simplify_list_columns leaves multi-value list columns as lists", {
  df <- tibble::tibble(x = list(c("a", "b"), "c"))
  out <- simplify_list_columns(df)
  expect_type(out$x, "list")
})

test_that("simplify_list_columns does not modify non-list columns", {
  df <- tibble::tibble(x = list("a", "b"), y = 1:2)
  out <- simplify_list_columns(df)
  expect_equal(out$y, 1:2)
})

# ---------------------------------------------------------------------------
# .parse_entity() — existing tests preserved, new additions below
# ---------------------------------------------------------------------------

test_that("parse_entity reports stage context in verbose mode and falls back safely", {
  bad_entity <- list(
    labels = list(en = "bad_label"),
    descriptions = list(en = "bad_description"),
    claims = list(P31 = "bad_claim"),
    sitelinks = list(enwiki = "bad_link")
  )

  expect_message(
    parsed <- wikitools:::.parse_entity(
      bad_entity,
      qid = "Q1",
      property = NULL,
      property_names = NULL,
      languages = "en",
      object_type = "instance",
      verbose = TRUE
    ),
    "stage 'labels'|stage 'descriptions'|stage 'instance_of/hierarchy'|stage 'sitelinks'"
  )

  expect_identical(parsed$qid, "Q1")
  expect_true(is.na(parsed$label_en))
  expect_true(is.na(parsed$description_en))
  expect_identical(parsed$instance_of[[1]], character(0))
  expect_identical(parsed$wikipedia_articles[[1]], character(0))
})

test_that("parse_entity falls back for numeric_list_property stage errors", {
  entity_without_claims <- list(
    labels = list(),
    descriptions = list(),
    sitelinks = list()
  )

  expect_message(
    parsed <- wikitools:::.parse_entity(
      entity_without_claims,
      qid = "Q2",
      property = NULL,
      property_names = NULL,
      languages = "en",
      numeric_list_properties = "P1082",
      numeric_list_property_names = "population",
      object_type = "instance",
      verbose = TRUE
    ),
    "stage 'numeric_list_property P1082'"
  )

  expect_true(is.na(parsed$population))
  expect_identical(parsed$population_n, 0L)
})

test_that("parse_entity extracts monolingualtext (P1448) values correctly", {
  make_claims <- function(pid, dv_df) {
    mainsnak <- data.frame(snaktype = "value", property = pid,
                           stringsAsFactors = FALSE)
    mainsnak$datavalue <- list(dv_df)
    claims <- data.frame(rank = "normal", stringsAsFactors = FALSE)
    claims$mainsnak <- mainsnak
    claims
  }

  entity <- list(
    labels       = list(en = list(value = "Pisces")),
    descriptions = list(en = list(value = "zodiac constellation")),
    claims       = list(
      P1448 = make_claims("P1448",
                          data.frame(text = "Pisces", language = "la",
                                     stringsAsFactors = FALSE)),
      P31   = make_claims("P31",
                          data.frame(id = "Q8928", stringsAsFactors = FALSE))
    ),
    sitelinks = list()
  )

  parsed <- wikitools:::.parse_entity(
    entity,
    qid            = "Q8679",
    property       = "P1448",
    property_names = "official_name",
    languages      = "en",
    object_type    = "instance",
    verbose        = FALSE
  )

  expect_identical(parsed$official_name[[1]], "Pisces")
})

test_that("parse_entity uses 'position_held' column name for object_type='position_held'", {
  entity <- list(
    labels       = list(en = list(value = "Test Person")),
    descriptions = list(),
    claims       = list(),
    sitelinks    = list()
  )
  parsed <- wikitools:::.parse_entity(
    entity, qid = "Q1", property = NULL, property_names = NULL,
    languages = "en", object_type = "position_held", verbose = FALSE
  )
  expect_true("position_held" %in% names(parsed))
  expect_false("instance_of"  %in% names(parsed))
})

test_that("verbose argument exists on public and internal wikidata instance helpers", {
  expect_true("verbose" %in% names(formals(wikitools::get_wikidata_instances)))
  expect_true("verbose" %in% names(formals(wikitools::resume_get_wikidata_instances)))
  expect_true("verbose" %in% names(formals(wikitools:::.fetch_qids_in_batches)))
  expect_true("verbose" %in% names(formals(wikitools:::.parse_entity)))
})

# ---------------------------------------------------------------------------
# get_wikidata_instances() — input validation
# ---------------------------------------------------------------------------

test_that("get_wikidata_instances rejects malformed class_qid", {
  expect_error(get_wikidata_instances("not_a_qid"), "class_qid")
})

test_that("get_wikidata_instances rejects malformed country QID", {
  expect_error(
    suppressMessages(get_wikidata_instances("Q5", country = "not_a_qid")),
    "country"
  )
})

test_that("get_wikidata_instances rejects invalid object_type", {
  expect_error(
    suppressMessages(get_wikidata_instances("Q5", object_type = "banana")),
    "object_type"
  )
})

# ---------------------------------------------------------------------------
# get_wikidata_instances() — integration via httptest fixtures
# Fixture: Q978708 (Prime Minister of East Timor) via P39, 6 position holders
# ---------------------------------------------------------------------------

with_mock_dir(".", {

  test_that("get_wikidata_instances returns a tibble", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_s3_class(result, "tbl_df")
  })

  test_that("get_wikidata_instances returns 6 rows for Q978708 position holders", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_equal(nrow(result), 6L)
  })

  test_that("get_wikidata_instances result has qid, label_en, label_es columns", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_true("qid"      %in% names(result))
    expect_true("label_en" %in% names(result))
    expect_true("label_es" %in% names(result))
  })

  test_that("get_wikidata_instances result includes wikipedia_articles list-column", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_true("wikipedia_articles" %in% names(result))
    expect_type(result$wikipedia_articles, "list")
  })

  test_that("get_wikidata_instances result includes position_held list-column", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_true("position_held" %in% names(result))
    expect_false("instance_of"  %in% names(result))
  })

  test_that("get_wikidata_instances QIDs are all expected East Timor PMs", {
    expected_qids <- c("Q727119", "Q1647887", "Q11509", "Q11664", "Q11665", "Q57519")
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_setequal(result$qid, expected_qids)
  })

  test_that("get_wikidata_instances label_en includes Xanana Gusmão", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_true("Xanana Gusmão" %in% result$label_en)
  })

  test_that("get_wikidata_instances wikipedia_articles are 'lang: Title' strings", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    all_arts <- unlist(result$wikipedia_articles)
    # Language codes may contain hyphens or underscores (e.g. be_x_old, zh-min-nan)
    expect_true(all(grepl("^[a-z0-9][a-z0-9_-]*: ", all_arts)))
  })

  test_that("get_wikidata_instances qid column is character", {
    result <- suppressMessages(
      get_wikidata_instances("Q978708", object_type = "position_held",
                             languages = c("en", "es"), batch_delay = 0)
    )
    expect_type(result$qid, "character")
    expect_true(all(grepl("^Q\\d+$", result$qid)))
  })

})

# ---------------------------------------------------------------------------
# resume_get_wikidata_instances() — validation
# ---------------------------------------------------------------------------

test_that("resume_get_wikidata_instances errors when partial_result lacks qid", {
  bad_partial <- tibble::tibble(notqid = "Q1")
  expect_error(
    resume_get_wikidata_instances(bad_partial, "Q978708"),
    "qid"
  )
})

test_that("resume_get_wikidata_instances rejects malformed class_qid", {
  partial <- tibble::tibble(qid = "Q1")
  expect_error(
    resume_get_wikidata_instances(partial, "bad_qid"),
    "class_qid"
  )
})

test_that("resume_get_wikidata_instances rejects invalid object_type", {
  partial <- tibble::tibble(qid = "Q1")
  expect_error(
    resume_get_wikidata_instances(partial, "Q978708", object_type = "wrong"),
    "object_type"
  )
})
