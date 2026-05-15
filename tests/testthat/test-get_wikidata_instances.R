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
  # Mimic the nested data.frame structure that fromJSON produces:
  # claims[[pid]] is a data.frame whose $mainsnak column is itself a data.frame,
  # with $datavalue as a list column inside it.

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

test_that("verbose argument exists on public and internal wikidata instance helpers", {
  expect_true("verbose" %in% names(formals(wikitools::get_wikidata_instances)))
  expect_true("verbose" %in% names(formals(wikitools::resume_get_wikidata_instances)))
  expect_true("verbose" %in% names(formals(wikitools:::.fetch_qids_in_batches)))
  expect_true("verbose" %in% names(formals(wikitools:::.parse_entity)))
})

