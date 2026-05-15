testthat::test_that("str_equivalent works as expected", {
  #' str_equivalent("  Café", "cafe") # TRUE
  expect_true(str_equivalent("  Café", "cafe"))
  #' str_equivalent("Hello\u00a0World", "hello world") # TRUE
  expect_true(str_equivalent("Hello\u00a0World", "hello world"))
  #' str_equivalent("Quote\"", "quote") # TRUE
  expect_true(str_equivalent("Quote\"", "quote"))
  #' str_equivalent("Case", "case") # TRUE
  expect_true(str_equivalent("Case", "case"))
  #' str_equivalent("Mismatch", "mismatch!") # FALSE
  expect_false(str_equivalent("Mismatch", "mismatch!"))
  
  # Simple case where a match exists
  expect_true(str_equivalent("Sucre", "sucre"))
  
  # Case where no match exists
  expect_false(str_equivalent("Santa Cruz", "sucre"))
  
  # Case where the string is empty
  expect_false(str_equivalent("", "sucre"))
  
  # Case where the pattern is empty
  expect_false(str_equivalent("Sucre", ""))
  
  # Case where both string and pattern are empty
  expect_true(str_equivalent("", ""))
  
  # Case-insensitive matching
  expect_true(str_equivalent("SUCRE", "sucre"))
  
  # Case with special characters
  expect_true(str_equivalent("Sucré", "sucre"))
  
  # Case with partial matching (should return FALSE since exact match is required)
  expect_false(str_equivalent("Suc", "sucre"))
})


testthat::test_that("str_equivalent_list works as expected", {
  # Simple case where a match exists
  expect_true(str_equivalent_list("Sucre", c("sucre", "La Paz", "Cochabamba")))
  
  # Case where no match exists
  expect_false(str_equivalent_list("Santa Cruz", c("sucre", "La Paz", "Cochabamba")))
  
  # Case where the list is empty
  expect_false(str_equivalent_list("Sucre", character(0)))
  
  # Case where the string is empty
  expect_false(str_equivalent_list("", c("sucre", "La Paz", "Cochabamba")))
  
  # Case where both string and list are empty
  expect_false(str_equivalent_list("", character(0)))
  
  # Case-insensitive matching
  expect_true(str_equivalent_list("SUCRE", c("sucre", "La Paz", "Cochabamba")))
  
  # Case with special characters
  expect_true(str_equivalent_list("Sucré", c("sucre", "La Paz", "Cochabamba")))
  
  # Case with partial matching (should return FALSE since exact match is required)
  expect_false(str_equivalent_list("Suc", c("sucre", "La Paz", "Cochabamba")))
  
  # Case where multiple matches exist in the list
  expect_true(str_equivalent_list("Sucre", c("sucre", "Sucre", "Cochabamba")))
})

testthat::test_that("equivalent_which works as expected", {
  # Simple case where a match exists
  expect_equal(equivalent_which("Sucre", c("sucre", "La Paz", "Cochabamba")), 1)
  
  # Case where no match exists
  expect_equal(equivalent_which("Santa Cruz", c("sucre", "La Paz", "Cochabamba")), integer(0))
  
  # Case where the list is empty
  expect_equal(equivalent_which("Sucre", character(0)), integer(0))
  
  # Case where the string is empty
  expect_equal(equivalent_which("", c("sucre", "La Paz", "Cochabamba")), integer(0))
  
  # Case where both string and list are empty
  expect_equal(equivalent_which("", character(0)), integer(0))
  
  # Case-insensitive matching
  expect_equal(equivalent_which("SUCRE", c("sucre", "La Paz", "Cochabamba")), 1)
  
  # Case with special characters
  expect_equal(equivalent_which("Sucré", c("sucre", "La Paz", "Cochabamba")), 1)
  
  # Case with partial matching (should return integer(0) since exact match is required)
  expect_equal(equivalent_which("Suc", c("sucre", "La Paz", "Cochabamba")), integer(0))
  
  # Case where multiple matches exist in the list
  expect_equal(equivalent_which("Sucre", c("sucre", "Sucre", "Cochabamba")), c(1, 2))
  # Case where multiple matches exist in the list with different cases
  expect_equal(equivalent_which("SUCRE", c("sucre", "Sucre", "Cochabamba")), c(1, 2))
})

testthat::test_that("equivalent_match works as expected", {
  # Simple case where a match exists
  expect_equal(equivalent_match("Sucre", c("sucre", "La Paz", "Cochabamba")), "sucre")
  
  # Case where no match exists
  expect_equal(equivalent_match("Santa Cruz", c("sucre", "La Paz", "Cochabamba")), NA)
  
  # Case where the list is empty
  expect_equal(equivalent_match("Sucre", character(0)), NA)
  
  # Case where the string is empty
  expect_equal(equivalent_match("", c("sucre", "La Paz", "Cochabamba")), NA)
  
  # Case where both string and list are empty
  expect_equal(equivalent_match("", character(0)), NA)
  
  # Case-insensitive matching
  expect_equal(equivalent_match("SUCRE", c("sucre", "La Paz", "Cochabamba")), "sucre")
  
  # Case with special characters
  expect_equal(equivalent_match("Sucré", c("sucre", "La Paz", "Cochabamba")), "sucre")
  
  # Case with partial matching (should return NA since exact match is required)
  expect_equal(equivalent_match("Suc", c("sucre", "La Paz", "Cochabamba")), NA)
  
  # Case where multiple matches exist in the list
  expect_equal(equivalent_match("Sucre", c("sucre", "Sucre", "Cochabamba")), c("sucre", "Sucre"))
})
