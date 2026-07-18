library(testthat)
library(wikitools)

# ==============================================================================
# str_equivalent
# ==============================================================================

test_that("str_equivalent returns TRUE for identical strings", {
  expect_true(str_equivalent("Sucre", "Sucre"))
  expect_true(str_equivalent("", ""))
})

test_that("str_equivalent ignores case", {
  expect_true(str_equivalent("SUCRE", "sucre"))
  expect_true(str_equivalent("La Paz", "LA PAZ"))
})

test_that("str_equivalent removes accents", {
  expect_true(str_equivalent("Café", "cafe"))
  expect_true(str_equivalent("São Paulo", "sao paulo"))
  expect_true(str_equivalent("Bogotá", "bogota"))
})

test_that("str_equivalent trims leading and trailing whitespace", {
  expect_true(str_equivalent("  Sucre  ", "Sucre"))
  expect_true(str_equivalent("Sucre", "   Sucre   "))
})

test_that("str_equivalent treats non-breaking spaces as regular spaces", {
  expect_true(str_equivalent("Hello\u00a0World", "Hello World"))
})

test_that("str_equivalent removes double quotes", {
  expect_true(str_equivalent('"Sucre"', "Sucre"))
  expect_true(str_equivalent('say "hello"', "say hello"))
})

test_that("str_equivalent handles combinations of normalizations", {
  # whitespace + quotes + accents + case all handled together
  expect_true(str_equivalent('  "CAFÉ"  ', "cafe"))
})

test_that("str_equivalent does not trim trailing non-breaking spaces (known pipeline order)", {
  # trimws() runs before nbsp replacement, so a trailing \u00a0 becomes a
  # trailing regular space that is never re-trimmed
  expect_false(str_equivalent("Cafe\u00a0", "cafe"))
})

test_that("str_equivalent returns FALSE for genuine mismatches", {
  expect_false(str_equivalent("Santa Cruz", "Sucre"))
  expect_false(str_equivalent("Suc", "Sucre"))
  expect_false(str_equivalent("Mismatch", "mismatch!"))
  expect_false(str_equivalent("Sucre", ""))
  expect_false(str_equivalent("", "Sucre"))
})

test_that("str_equivalent is vectorized over both arguments", {
  result <- str_equivalent(c("Cafe", "Tea"), c("café", "TEA"))
  expect_equal(result, c(TRUE, TRUE))

  result2 <- str_equivalent(c("a", "b", "c"), "a")
  expect_equal(result2, c(TRUE, FALSE, FALSE))
})

test_that("str_equivalent propagates NA", {
  expect_true(is.na(str_equivalent(NA_character_, "test")))
  expect_true(is.na(str_equivalent("test", NA_character_)))
})

# ==============================================================================
# equivalent_which
# ==============================================================================

test_that("equivalent_which returns the correct position of a match", {
  expect_equal(equivalent_which("Sucre", c("sucre", "La Paz", "Cochabamba")), 1L)
})

test_that("equivalent_which finds a match that is not at position 1", {
  expect_equal(equivalent_which("La Paz", c("Sucre", "la paz", "Cochabamba")), 2L)
  expect_equal(equivalent_which("Cochabamba", c("Sucre", "La Paz", "COCHABAMBA")), 3L)
})

test_that("equivalent_which returns integer(0) when there is no match", {
  expect_equal(equivalent_which("Santa Cruz", c("Sucre", "La Paz")), integer(0))
})

test_that("equivalent_which returns all positions when multiple elements match", {
  expect_equal(equivalent_which("sucre", c("sucre", "Sucre", "La Paz")), c(1L, 2L))
})

test_that("equivalent_which returns integer(0) for empty string_list", {
  expect_equal(equivalent_which("Sucre", character(0)), integer(0))
})

test_that("equivalent_which handles accent and case normalization", {
  expect_equal(equivalent_which("Bogotá", c("other", "bogota")), 2L)
})

# ==============================================================================
# equivalent_match
# ==============================================================================

test_that("equivalent_match returns the matched element in its original form", {
  expect_equal(equivalent_match("sucre", c("Sucre", "La Paz")), "Sucre")
  expect_equal(equivalent_match("café", c("other", "Cafe")), "Cafe")
})

test_that("equivalent_match returns NA when there is no match", {
  expect_equal(equivalent_match("Santa Cruz", c("Sucre", "La Paz")), NA)
  expect_equal(equivalent_match("Sucre", character(0)), NA)
  expect_equal(equivalent_match("", c("Sucre", "La Paz")), NA)
})

test_that("equivalent_match returns all matching elements when multiple match", {
  result <- equivalent_match("sucre", c("sucre", "Sucre", "La Paz"))
  expect_equal(result, c("sucre", "Sucre"))
})

test_that("equivalent_match preserves the original string form from the vector", {
  # The returned value is the element of string_list, not the query
  result <- equivalent_match("SUCRE", c("Sucre"))
  expect_equal(result, "Sucre")
})

# ==============================================================================
# str_equivalent_list
# ==============================================================================

test_that("str_equivalent_list returns TRUE when a match exists", {
  expect_true(str_equivalent_list("Sucre", c("other", "sucre")))
  expect_true(str_equivalent_list("Café", c("cafe", "tea")))
})

test_that("str_equivalent_list returns FALSE when no match exists", {
  expect_false(str_equivalent_list("Santa Cruz", c("Sucre", "La Paz")))
  expect_false(str_equivalent_list("Suc", c("Sucre", "La Paz")))
})

test_that("str_equivalent_list returns FALSE for empty string_list", {
  expect_false(str_equivalent_list("Sucre", character(0)))
})

test_that("str_equivalent_list returns FALSE when the query is empty", {
  expect_false(str_equivalent_list("", c("Sucre", "La Paz")))
})

test_that("str_equivalent_list returns TRUE when multiple elements in list match", {
  expect_true(str_equivalent_list("sucre", c("sucre", "Sucre", "La Paz")))
})

test_that("str_equivalent_list returns NA when no match and list contains NA", {
  # any(c(FALSE, NA)) is NA in R — documented behavior, not a bug
  result <- str_equivalent_list("nomatch", c("other", NA))
  expect_true(is.na(result))
})

test_that("str_equivalent_list returns TRUE when match exists alongside NA in list", {
  expect_true(str_equivalent_list("Sucre", c(NA, "sucre")))
})
