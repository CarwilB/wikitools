library(testthat)
library(wikitools)

# Use a fixed retrieved date throughout to keep expected strings stable
FIXED_DATE <- "2024-06-15"
FIXED_DATE_FMT <- "+2024-06-15T00:00:00Z/11"

# ==============================================================================
# create_quick_statement — string type (default)
# ==============================================================================

test_that("string type produces correct output", {
  result <- create_quick_statement("Q14579", "P348", "6.13.7")
  expect_equal(result, 'Q14579 | P348 | "6.13.7"')
})

test_that("string type is the default when type is not specified", {
  expect_equal(
    create_quick_statement("Q1", "P31", "some value"),
    'Q1 | P31 | "some value"'
  )
})

test_that("string value containing special characters is quoted correctly", {
  result <- create_quick_statement("Q1", "P1476", "Hello, world!")
  expect_equal(result, 'Q1 | P1476 | "Hello, world!"')
})

# ==============================================================================
# create_quick_statement — monolingual type
# ==============================================================================

test_that("monolingual type produces lang:\"value\" format", {
  result <- create_quick_statement("Q935", "P1559", "Isaac Newton",
                                   lang = "en", type = "monolingual")
  expect_equal(result, 'Q935 | P1559 | en:"Isaac Newton"')
})

test_that("monolingual type uses specified language code", {
  result <- create_quick_statement("Q1001", "P1559", "Mahatma Gandhi",
                                   lang = "es", type = "monolingual")
  expect_equal(result, 'Q1001 | P1559 | es:"Mahatma Gandhi"')
})

# ==============================================================================
# create_quick_statement — label type
# ==============================================================================

test_that("label via type = 'label' produces Llang format", {
  result <- create_quick_statement("Q1001", "P1", "Mahatma Gandhi",
                                   lang = "en", type = "label")
  expect_equal(result, 'Q1001 | Len | "Mahatma Gandhi"')
})

test_that("label via property = 'L' produces Llang format", {
  result <- create_quick_statement("Q1001", "L", "Mahatma Gandhi", lang = "en")
  expect_equal(result, 'Q1001 | Len | "Mahatma Gandhi"')
})

test_that("label with non-English language uses correct lang code", {
  result <- create_quick_statement("Q1001", "L", "Gandhi", lang = "es")
  expect_equal(result, 'Q1001 | Les | "Gandhi"')
})

# ==============================================================================
# create_quick_statement — description type
# ==============================================================================

test_that("description via type = 'description' produces Dlang format", {
  result <- create_quick_statement("Q1001", "P1", "Indian activist",
                                   lang = "en", type = "description")
  expect_equal(result, 'Q1001 | Den | "Indian activist"')
})

test_that("description via property = 'D' produces Dlang format", {
  result <- create_quick_statement("Q1001", "D", "Indian activist", lang = "en")
  expect_equal(result, 'Q1001 | Den | "Indian activist"')
})

# ==============================================================================
# create_quick_statement — alias type
# ==============================================================================

test_that("alias via type = 'alias' produces Alang format", {
  result <- create_quick_statement("Q1001", "P1", "MKG",
                                   lang = "en", type = "alias")
  expect_equal(result, 'Q1001 | Aen | "MKG"')
})

test_that("alias via property = 'A' produces Alang format", {
  result <- create_quick_statement("Q1001", "A", "MKG", lang = "en")
  expect_equal(result, 'Q1001 | Aen | "MKG"')
})

# ==============================================================================
# create_quick_statement — item / time / quantity / coordinate types
# ==============================================================================

test_that("item type outputs value without quotes", {
  result <- create_quick_statement("Q42", "P19", "Q350", type = "item")
  expect_equal(result, "Q42 | P19 | Q350")
})

test_that("time type outputs value without quotes", {
  result <- create_quick_statement("Q42", "P569", "+1952-03-11T00:00:00Z/11",
                                   type = "time")
  expect_equal(result, "Q42 | P569 | +1952-03-11T00:00:00Z/11")
})

test_that("quantity type outputs numeric value without quotes", {
  result <- create_quick_statement("Q42", "P1082", "42", type = "quantity")
  expect_equal(result, "Q42 | P1082 | 42")
})

test_that("coordinate type outputs value without quotes", {
  result <- create_quick_statement("Q42", "P625", "@51.5074/0.1278",
                                   type = "coordinate")
  expect_equal(result, "Q42 | P625 | @51.5074/0.1278")
})

# ==============================================================================
# create_quick_statement — LAST keyword
# ==============================================================================

test_that("LAST is accepted as a valid QID", {
  result <- create_quick_statement("LAST", "P31", "Q5", type = "item")
  expect_equal(result, "LAST | P31 | Q5")
})

# ==============================================================================
# create_quick_statement — reference_url
# ==============================================================================

test_that("reference_url adds S854 block with S813 date", {
  result <- create_quick_statement(
    "Q42", "P19", "Q350",
    type = "item",
    reference_url = "https://example.com",
    retrieved_date = FIXED_DATE
  )
  expect_equal(
    result,
    paste0('Q42 | P19 | Q350 | S854 | "https://example.com" | S813 | ', FIXED_DATE_FMT)
  )
})

# ==============================================================================
# create_quick_statement — reference_qid
# ==============================================================================

test_that("reference_qid adds S248 block with S813 date", {
  result <- create_quick_statement(
    "Q42", "P19", "Q350",
    type = "item",
    reference_qid = "Q36578",
    retrieved_date = FIXED_DATE
  )
  expect_equal(
    result,
    paste0("Q42 | P19 | Q350 | S248 | Q36578 | S813 | ", FIXED_DATE_FMT)
  )
})

test_that("both reference_url and reference_qid can be combined", {
  result <- create_quick_statement(
    "Q42", "P19", "Q350",
    type = "item",
    reference_qid = "Q36578",
    reference_url = "https://example.com",
    retrieved_date = FIXED_DATE
  )
  expect_match(result, "S248 | Q36578")
  expect_match(result, 'S854 | "https://example.com"')
  expect_match(result, paste0("S813 | ", FIXED_DATE_FMT))
})

test_that("retrieved_date defaults to today when not supplied", {
  today_fmt <- format(Sys.Date(), "+%Y-%m-%dT00:00:00Z/11")
  result <- create_quick_statement(
    "Q1", "P31", "Q5",
    type = "item",
    reference_url = "https://example.com"
  )
  expect_match(result, today_fmt, fixed = TRUE)
})

test_that("retrieved_date accepts a Date object", {
  result <- create_quick_statement(
    "Q1", "P31", "Q5",
    type = "item",
    reference_url = "https://x.com",
    retrieved_date = as.Date("2023-01-01")
  )
  expect_match(result, "+2023-01-01T00:00:00Z/11", fixed = TRUE)
})

# ==============================================================================
# create_quick_statement — qualifiers
# ==============================================================================

test_that("qualifier is appended after the main value", {
  result <- create_quick_statement(
    "Q42", "P1098", "100",
    type = "quantity",
    qualifiers = list(P585 = "+2020-01-01T00:00:00Z/11")
  )
  expect_equal(result, "Q42 | P1098 | 100 | P585 | +2020-01-01T00:00:00Z/11")
})

test_that("multiple qualifiers are all appended in order", {
  result <- create_quick_statement(
    "Q42", "P1098", "100",
    type = "quantity",
    qualifiers = list(P276 = "Q750", P585 = "+2024-01-01T00:00:00Z/9")
  )
  expect_match(result, "P276 | Q750")
  expect_match(result, "P585 | \\+2024-01-01T00:00:00Z/9")
})

test_that("qualifiers appear before reference block", {
  result <- create_quick_statement(
    "Q42", "P1098", "100",
    type = "quantity",
    qualifiers = list(P585 = "+2020-01-01T00:00:00Z/11"),
    reference_qid = "Q123",
    retrieved_date = FIXED_DATE
  )
  qual_pos <- regexpr("P585", result)
  ref_pos  <- regexpr("S248", result)
  expect_true(qual_pos < ref_pos)
})

# ==============================================================================
# create_quick_statement — comment
# ==============================================================================

test_that("comment is appended at the end wrapped in /* */", {
  result <- create_quick_statement("Q42", "P31", "Q5",
                                   type = "item",
                                   comment = "batch import")
  expect_equal(result, "Q42 | P31 | Q5 | /* batch import */")
})

test_that("comment appears after reference block when both provided", {
  result <- create_quick_statement(
    "Q42", "P31", "Q5",
    type = "item",
    reference_url = "https://example.com",
    retrieved_date = FIXED_DATE,
    comment = "batch import"
  )
  expect_true(endsWith(result, "/* batch import */"))
})

# ==============================================================================
# create_quick_statement — error handling
# ==============================================================================

test_that("invalid qid format raises an error", {
  expect_error(create_quick_statement("42", "P31", "Q5"), "qid must be in format")
  expect_error(create_quick_statement("q42", "P31", "Q5"), "qid must be in format")
  expect_error(create_quick_statement("QQ42", "P31", "Q5"), "qid must be in format")
})

test_that("missing lang for label raises an error", {
  expect_error(
    create_quick_statement("Q1", "L", "value"),
    "lang parameter is required for labels"
  )
  expect_error(
    create_quick_statement("Q1", "P1", "value", type = "label"),
    "lang parameter is required for labels"
  )
})

test_that("missing lang for description raises an error", {
  expect_error(
    create_quick_statement("Q1", "D", "value"),
    "lang parameter is required for descriptions"
  )
})

test_that("missing lang for alias raises an error", {
  expect_error(
    create_quick_statement("Q1", "A", "value"),
    "lang parameter is required for aliases"
  )
})

test_that("missing lang for monolingual raises an error", {
  expect_error(
    create_quick_statement("Q1", "P1559", "value", type = "monolingual"),
    "lang parameter is required for monolingual text"
  )
})

test_that("invalid property format for string type raises an error", {
  expect_error(
    create_quick_statement("Q1", "31", "value"),
    "property must be in format 'P123'"
  )
})

test_that("invalid property format for item type raises an error", {
  expect_error(
    create_quick_statement("Q1", "property", "Q5", type = "item"),
    "property must be in format 'P123'"
  )
})

test_that("invalid type raises an error", {
  expect_error(
    create_quick_statement("Q1", "P31", "value", type = "unknown"),
    "Invalid type"
  )
})

test_that("invalid reference_qid format raises an error", {
  expect_error(
    create_quick_statement("Q1", "P31", "Q5", type = "item",
                           reference_qid = "not-a-qid"),
    "reference_qid must be in format"
  )
})

test_that("invalid qualifier property format raises an error", {
  expect_error(
    create_quick_statement("Q1", "P31", "Q5", type = "item",
                           qualifiers = list(bad_prop = "Q750")),
    "Qualifier property must be in format"
  )
})

# ==============================================================================
# create_quick_statement — warnings
# ==============================================================================

test_that("reference on label via property = 'L' triggers a warning", {
  expect_warning(
    create_quick_statement("Q1", "L", "Newton", lang = "en",
                           reference_url = "https://example.com"),
    "References cannot be added to labels"
  )
})

test_that("reference on description via property = 'D' triggers a warning", {
  expect_warning(
    create_quick_statement("Q1", "D", "physicist", lang = "en",
                           reference_qid = "Q123"),
    "References cannot be added to labels"
  )
})

test_that("reference on alias via property = 'A' triggers a warning", {
  expect_warning(
    create_quick_statement("Q1", "A", "MKG", lang = "en",
                           reference_url = "https://example.com"),
    "References cannot be added to labels"
  )
})

test_that("reference on label via type = 'label' triggers a warning", {
  expect_warning(
    create_quick_statement("Q1", "P1", "Newton", lang = "en",
                           type = "label",
                           reference_url = "https://example.com"),
    "References cannot be added to labels"
  )
})

test_that("label with reference returns result without reference block", {
  result <- suppressWarnings(
    create_quick_statement("Q1", "L", "Newton", lang = "en",
                           reference_url = "https://example.com")
  )
  expect_false(grepl("S854", result))
  expect_equal(result, 'Q1 | Len | "Newton"')
})

# ==============================================================================
# add_quick_statement_column
# ==============================================================================

test_that("add_quick_statement_column adds a quick_statement column", {
  df <- data.frame(qid = c("Q1", "Q2"), val = c("a", "b"),
                   stringsAsFactors = FALSE)
  result <- add_quick_statement_column(df, qid, "P31", val)
  expect_true("quick_statement" %in% names(result))
  expect_equal(nrow(result), 2L)
})

test_that("add_quick_statement_column produces correct string values row-wise", {
  df <- data.frame(qid = c("Q10", "Q20"), val = c("foo", "bar"),
                   stringsAsFactors = FALSE)
  result <- add_quick_statement_column(df, qid, "P31", val)
  expect_equal(result$quick_statement[1], 'Q10 | P31 | "foo"')
  expect_equal(result$quick_statement[2], 'Q20 | P31 | "bar"')
})

test_that("add_quick_statement_column passes ... arguments to create_quick_statement", {
  df <- data.frame(qid = "Q1", val = "Q5", stringsAsFactors = FALSE)
  result <- add_quick_statement_column(df, qid, "P31", val, type = "item")
  expect_equal(result$quick_statement, "Q1 | P31 | Q5")
})

# ==============================================================================
# add_quick_statement_column_q
# ==============================================================================

test_that("add_quick_statement_column_q appends qualifiers to each row", {
  df <- data.frame(qid = c("Q1", "Q2"), pop = c("100", "200"),
                   stringsAsFactors = FALSE)
  result <- add_quick_statement_column_q(
    df, qid, "P1098", pop,
    qualifiers = list(P585 = "+2020-01-01T00:00:00Z/11"),
    type = "quantity"
  )
  expect_true("quick_statement" %in% names(result))
  expect_match(result$quick_statement[1], "P585 | \\+2020-01-01T00:00:00Z/11")
  expect_match(result$quick_statement[2], "P585 | \\+2020-01-01T00:00:00Z/11")
})

test_that("add_quick_statement_column_q coerces value_col to character", {
  df <- data.frame(qid = "Q1", pop = 42L, stringsAsFactors = FALSE)
  result <- add_quick_statement_column_q(
    df, qid, "P1082", pop,
    type = "quantity"
  )
  expect_match(result$quick_statement, "42")
})

# ==============================================================================
# remove_quick_statement_column
# ==============================================================================

test_that("remove_quick_statement_column prepends '-' to each statement", {
  df <- data.frame(qid = c("Q1", "Q2"), val = c("Q5", "Q6"),
                   stringsAsFactors = FALSE)
  result <- remove_quick_statement_column(df, qid, "P31", val, type = "item")
  expect_true(all(startsWith(result$quick_statement, "-")))
  expect_equal(result$quick_statement[1], "-Q1 | P31 | Q5")
  expect_equal(result$quick_statement[2], "-Q2 | P31 | Q6")
})

test_that("remove_quick_statement_column returns same number of rows as input", {
  df <- data.frame(qid = paste0("Q", 1:5),
                   val = paste0("Q", 10:14),
                   stringsAsFactors = FALSE)
  result <- remove_quick_statement_column(df, qid, "P31", val, type = "item")
  expect_equal(nrow(result), 5L)
})
