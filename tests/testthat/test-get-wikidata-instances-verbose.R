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

test_that("verbose argument exists on public and internal wikidata instance helpers", {
  expect_true("verbose" %in% names(formals(wikitools::get_wikidata_instances)))
  expect_true("verbose" %in% names(formals(wikitools::resume_get_wikidata_instances)))
  expect_true("verbose" %in% names(formals(wikitools:::.fetch_qids_in_batches)))
  expect_true("verbose" %in% names(formals(wikitools:::.parse_entity)))
})
