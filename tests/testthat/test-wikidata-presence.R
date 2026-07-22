# Tests for wikidata-presence.R
#
# Real Wikidata fixture: instances of Q978708 (Prime Minister of East Timor),
# retrieved via object_type = "position_held" (P39) and frozen as an RDS file.
# Tests are run entirely offline via local_mocked_bindings(); no API calls made.
#
# Fixture: tests/testthat/fixtures/inst_q978708.rds
#   6 rows — Estanislau da Silva (Q727119), Rui Maria de Araújo (Q1647887),
#             Xanana Gusmão (Q11509), Mari Alkatiri (Q11664),
#             José Ramos-Horta (Q11665), Taur Matan Ruak (Q57519)
#
# Language-presence facts confirmed from fixture:
#   All 6 have: en, de, fr, pt, es, id
#   tet (Tetum): 5 of 6 — Estanislau da Silva (Q727119) does NOT have tet
#   84 unique language codes across all 6

# Load frozen fixture once at file-source time
inst_q978708 <- readRDS(testthat::test_path("fixtures", "inst_q978708.rds"))

# Convenience: run the function with the fixture injected
with_pm_fixture <- function(expr) {
  local_mocked_bindings(
    get_wikidata_instances = function(...) inst_q978708,
    .package = "wikitools"
  )
  eval(substitute(expr), parent.frame())
}

# ===========================================================================
# get_wikidata_instances() — new object_type = "position_held" support
# ===========================================================================

test_that("get_wikidata_instances rejects invalid object_type", {
  expect_error(
    get_wikidata_instances("Q978708", object_type = "banana"),
    'object_type must be'
  )
})

test_that("get_wikidata_instances validates property_id format in .build_sparql_query", {
  expect_error(
    wikitools:::.build_sparql_query("Q978708", property_id = "not_a_property"),
    "property_id must be a Wikidata property ID"
  )
})

test_that(".build_sparql_query accepts P39 and produces correct SPARQL", {
  q <- wikitools:::.build_sparql_query("Q978708", property_id = "P39", limit = 100)
  expect_true(grepl("wdt:P39", q, fixed = TRUE))
  expect_true(grepl("wd:Q978708", q, fixed = TRUE))
  expect_true(grepl("LIMIT 100", q, fixed = TRUE))
})

test_that(".build_sparql_query still works for P31 and P279", {
  q31  <- wikitools:::.build_sparql_query("Q5", property_id = "P31")
  q279 <- wikitools:::.build_sparql_query("Q5", property_id = "P279")
  expect_true(grepl("wdt:P31",  q31,  fixed = TRUE))
  expect_true(grepl("wdt:P279", q279, fixed = TRUE))
})

# ===========================================================================
# wikidata_instance_wikipedia_presence() — input validation
# ===========================================================================

test_that("wikidata_instance_wikipedia_presence errors if class_qid is not character", {
  expect_error(
    suppressMessages(wikidata_instance_wikipedia_presence(123))
  )
})

test_that("wikidata_instance_wikipedia_presence errors if languages is not character", {
  with_pm_fixture({
    expect_error(
      wikidata_instance_wikipedia_presence("Q978708", languages = 42)
    )
  })
})

# ===========================================================================
# wikidata_instance_wikipedia_presence() — return structure
# ===========================================================================

test_that("wikidata_instance_wikipedia_presence returns a named list with three elements", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "fr"))
    expect_type(res, "list")
    expect_named(res, c("instances", "presence", "data"))
  })
})

test_that("$instances is the tibble returned by get_wikidata_instances", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en")
    expect_identical(res$instances, inst_q978708)
  })
})

test_that("$presence is a logical matrix", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "fr", "pt"))
    expect_true(is.matrix(res$presence))
    expect_type(res$presence, "logical")
  })
})

test_that("$data is a tibble", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en")
    expect_s3_class(res$data, "tbl_df")
  })
})

# ===========================================================================
# $presence matrix — dimensions and row/column names
# ===========================================================================

test_that("presence matrix has 6 rows (one per PM) and correct row names", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "fr"))
    expect_equal(nrow(res$presence), 6L)
    expect_true(all(inst_q978708$qid %in% rownames(res$presence)))
  })
})

test_that("presence matrix columns match the requested languages", {
  with_pm_fixture({
    langs <- c("en", "de", "pt", "fr")
    res   <- wikidata_instance_wikipedia_presence("Q978708", languages = langs)
    expect_equal(colnames(res$presence), langs)
  })
})

test_that("all 6 PMs have en=TRUE in presence matrix", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "fr"))
    expect_true(all(res$presence[, "en"]))
  })
})

test_that("all 6 PMs have de=TRUE in presence matrix", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "de"))
    expect_true(all(res$presence[, "de"]))
  })
})

test_that("exactly 5 of 6 PMs have tet=TRUE in presence matrix", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "tet"))
    expect_equal(sum(res$presence[, "tet"]), 5L)
  })
})

test_that("Estanislau da Silva (Q727119) does not have tet presence", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "tet"))
    expect_false(res$presence["Q727119", "tet"])
  })
})

test_that("Xanana Gusmão (Q11509) has tet presence", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "tet"))
    expect_true(res$presence["Q11509", "tet"])
  })
})

test_that("presence is FALSE for a language no PM has", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence(
      "Q978708", languages = c("en", "zz_nonexistent")
    )
    expect_true(all(!res$presence[, "zz_nonexistent"]))
  })
})

# ===========================================================================
# $data tibble — content
# ===========================================================================

test_that("$data has qid, label_en, label_es, and one column per language", {
  with_pm_fixture({
    langs <- c("en", "fr", "pt")
    res   <- wikidata_instance_wikipedia_presence("Q978708", languages = langs,
                                                  include_labels = TRUE)
    expected_cols <- c("qid", "label_en", "label_es", langs)
    expect_true(all(expected_cols %in% names(res$data)))
  })
})

test_that("$data language columns are integer (0/1)", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "fr"))
    expect_type(res$data$en, "integer")
    expect_type(res$data$fr, "integer")
    expect_true(all(res$data$en %in% c(0L, 1L)))
  })
})

test_that("$data en column is all 1s (every PM has an English article)", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "tet"))
    expect_true(all(res$data$en == 1L))
  })
})

test_that("$data tet column sums to 5", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = c("en", "tet"))
    expect_equal(sum(res$data$tet), 5L)
  })
})

test_that("$data has 6 rows, one per PM", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en")
    expect_equal(nrow(res$data), 6L)
  })
})

# ===========================================================================
# include_labels parameter
# ===========================================================================

test_that("include_labels = TRUE adds label_en and label_es to $data", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en",
                                                include_labels = TRUE)
    expect_true("label_en" %in% names(res$data))
    expect_true("label_es" %in% names(res$data))
  })
})

test_that("include_labels = FALSE omits label columns from $data", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en",
                                                include_labels = FALSE)
    expect_false("label_en" %in% names(res$data))
    expect_false("label_es" %in% names(res$data))
    expect_true("qid" %in% names(res$data))
  })
})

test_that("label_en values match expected PM names", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en",
                                                include_labels = TRUE)
    expect_true("Xanana Gusmão" %in% res$data$label_en)
    expect_true("José Ramos-Horta" %in% res$data$label_en)
    expect_true("Mari Alkatiri" %in% res$data$label_en)
  })
})

# ===========================================================================
# languages = NULL — auto-discovery
# ===========================================================================

test_that("languages = NULL auto-discovers all languages and produces wide $data", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = NULL)
    # Should have many more language columns than a manual set
    lang_cols <- setdiff(names(res$data), c("qid", "label_en", "label_es"))
    expect_gt(length(lang_cols), 50L)
    expect_true("en" %in% lang_cols)
    expect_true("fr" %in% lang_cols)
  })
})

test_that("languages = NULL presence matrix column names are sorted language codes", {
  with_pm_fixture({
    res   <- wikidata_instance_wikipedia_presence("Q978708", languages = NULL)
    langs <- colnames(res$presence)
    expect_equal(langs, sort(langs))
  })
})

# ===========================================================================
# drop_other_langs parameter
# ===========================================================================

test_that("drop_other_langs = TRUE restricts lang_sets to the requested languages", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence(
      "Q978708", languages = c("en", "tet"), drop_other_langs = TRUE
    )
    expect_equal(colnames(res$presence), c("en", "tet"))
  })
})

# ===========================================================================
# debug parameter
# ===========================================================================

test_that("debug = TRUE appends a $debug element to the result", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en",
                                                debug = TRUE)
    expect_true("debug" %in% names(res))
    expect_type(res$debug, "list")
  })
})

test_that("debug = FALSE (default) does not add $debug element", {
  with_pm_fixture({
    res <- wikidata_instance_wikipedia_presence("Q978708", languages = "en")
    expect_false("debug" %in% names(res))
  })
})

# ===========================================================================
# Empty instances edge case
# ===========================================================================

test_that("empty instances returns list with zero-row presence matrix and empty data", {
  empty_inst <- inst_q978708[0, ]
  local_mocked_bindings(
    get_wikidata_instances = function(...) empty_inst,
    .package = "wikitools"
  )
  res <- wikidata_instance_wikipedia_presence("Q999999", languages = c("en", "fr"))
  expect_equal(nrow(res$instances), 0L)
  expect_equal(nrow(res$presence), 0L)
  expect_equal(ncol(res$presence), 2L)
  expect_s3_class(res$data, "tbl_df")
  expect_equal(nrow(res$data), 0L)
})

test_that("empty instances with languages = NULL returns zero-column presence matrix", {
  empty_inst <- inst_q978708[0, ]
  local_mocked_bindings(
    get_wikidata_instances = function(...) empty_inst,
    .package = "wikitools"
  )
  res <- wikidata_instance_wikipedia_presence("Q999999", languages = NULL)
  expect_equal(dim(res$presence), c(0L, 0L))
})

# ===========================================================================
# resume_wikidata_instance_wikipedia_presence() — structure
# ===========================================================================

test_that("resume_wikidata_instance_wikipedia_presence errors with bad partial_result", {
  expect_error(
    resume_wikidata_instance_wikipedia_presence(
      partial_result = list(not_instances = tibble::tibble()),
      class_qid = "Q978708"
    ),
    "partial_result must be"
  )
})

test_that("resume_wikidata_instance_wikipedia_presence returns same structure as main fn", {
  partial <- list(instances = inst_q978708[1:3, ])
  local_mocked_bindings(
    resume_get_wikidata_instances = function(...) inst_q978708,
    .package = "wikitools"
  )
  res <- resume_wikidata_instance_wikipedia_presence(
    partial_result = partial,
    class_qid      = "Q978708",
    languages      = c("en", "fr")
  )
  expect_named(res, c("instances", "presence", "data"))
  expect_equal(nrow(res$presence), 6L)
  expect_equal(colnames(res$presence), c("en", "fr"))
})
