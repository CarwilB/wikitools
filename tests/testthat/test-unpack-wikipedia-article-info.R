test_that("unpack_wikipedia_article_info adds correct columns", {
  # Create test data
  test_df <- tibble::tibble(
    id = 1:2,
    wikipedia_articles = list(
      c("en: Python", "es: Pitón", "fr: Python"),
      c("en: Ruby", "de: Rubin")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en", "es"))

  # Check that new columns exist
  expect_true("en_present" %in% names(result))
  expect_true("en_article" %in% names(result))
  expect_true("en_url" %in% names(result))
  expect_true("es_present" %in% names(result))
  expect_true("es_article" %in% names(result))
  expect_true("es_url" %in% names(result))

  # Check data types
  expect_true(is.logical(result$en_present))
  expect_true(is.character(result$en_article))
  expect_true(is.character(result$en_url))
})

test_that("unpack_wikipedia_article_info correctly identifies presence", {
  test_df <- tibble::tibble(
    id = 1:3,
    wikipedia_articles = list(
      c("en: Article 1", "es: Artículo 1"),
      c("fr: Article 2"),
      c("en: Article 3")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en", "es"))

  # Row 1: has both en and es
  expect_true(result$en_present[1])
  expect_true(result$es_present[1])

  # Row 2: has neither en nor es
  expect_false(result$en_present[2])
  expect_false(result$es_present[2])

  # Row 3: has en but not es
  expect_true(result$en_present[3])
  expect_false(result$es_present[3])
})

test_that("unpack_wikipedia_article_info extracts correct article titles", {
  test_df <- tibble::tibble(
    id = 1,
    wikipedia_articles = list(
      c("en: Multiword Article Title", "es: Título del Artículo")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en", "es"))

  expect_equal(result$en_article[1], "Multiword Article Title")
  expect_equal(result$es_article[1], "Título del Artículo")
})

test_that("unpack_wikipedia_article_info constructs correct URLs", {
  test_df <- tibble::tibble(
    id = 1,
    wikipedia_articles = list(
      c("en: Python Programming", "es: Lenguaje Python")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en", "es"))

  expect_equal(
    result$en_url[1],
    "https://en.wikipedia.org/wiki/Python_Programming"
  )
  expect_equal(
    result$es_url[1],
    "https://es.wikipedia.org/wiki/Lenguaje_Python"
  )
})

test_that("unpack_wikipedia_article_info handles missing languages as NA", {
  test_df <- tibble::tibble(
    id = 1:2,
    wikipedia_articles = list(
      c("en: Python"),
      c("fr: Python")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en", "es"))

  # Row 1: has en, not es
  expect_equal(result$en_article[1], "Python")
  expect_true(is.na(result$es_article[1]))
  expect_true(is.na(result$es_url[1]))

  # Row 2: doesn't have en
  expect_true(is.na(result$en_article[2]))
  expect_true(is.na(result$en_url[2]))
})

test_that("unpack_wikipedia_article_info returns a tibble", {
  test_df <- tibble::tibble(
    id = 1,
    wikipedia_articles = list(c("en: Test"))
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en"))

  expect_s3_class(result, "tbl_df")
})

test_that("unpack_wikipedia_article_info preserves original columns", {
  test_df <- tibble::tibble(
    id = 1:2,
    name = c("A", "B"),
    wikipedia_articles = list(
      c("en: Python"),
      c("en: Ruby")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en"))

  expect_equal(result$id, test_df$id)
  expect_equal(result$name, test_df$name)
  expect_equal(nrow(result), nrow(test_df))
})

test_that("unpack_wikipedia_article_info works with custom column name", {
  test_df <- tibble::tibble(
    id = 1,
    my_articles = list(c("en: Python"))
  )

  result <- unpack_wikipedia_article_info(test_df, wiki_col = "my_articles", langs = c("en"))

  expect_true("en_present" %in% names(result))
  expect_equal(result$en_article[1], "Python")
})

test_that("unpack_wikipedia_article_info handles multiple language codes", {
  test_df <- tibble::tibble(
    id = 1,
    wikipedia_articles = list(
      c("en: English", "es: Spanish", "fr: French", "de: German")
    )
  )

  result <- unpack_wikipedia_article_info(
    test_df,
    langs = c("en", "es", "fr", "de", "pt")
  )

  # Check all requested languages are present
  for (lang in c("en", "es", "fr", "de", "pt")) {
    expect_true(paste0(lang, "_present") %in% names(result))
    expect_true(paste0(lang, "_article") %in% names(result))
    expect_true(paste0(lang, "_url") %in% names(result))
  }

  # Check values
  expect_true(result$en_present[1])
  expect_true(result$es_present[1])
  expect_true(result$fr_present[1])
  expect_true(result$de_present[1])
  expect_false(result$pt_present[1]) # Not present
})

test_that("unpack_wikipedia_article_info requires valid inputs", {
  # Not a data frame
  expect_error(
    unpack_wikipedia_article_info(list(x = 1)),
    "`df` must be a data frame"
  )

  # Missing column
  expect_error(
    unpack_wikipedia_article_info(
      tibble::tibble(id = 1),
      wiki_col = "missing_col"
    ),
    "Column 'missing_col' not found"
  )

  # Invalid langs argument
  expect_error(
    unpack_wikipedia_article_info(
      tibble::tibble(id = 1, wikipedia_articles = list(c("en: Test"))),
      langs = numeric()
    ),
    "`langs` must be a non-empty character vector"
  )
})

test_that("unpack_wikipedia_article_info handles empty article lists", {
  test_df <- tibble::tibble(
    id = 1:2,
    wikipedia_articles = list(
      character(0),
      c("en: Python")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en", "es"))

  # Row with empty list
  expect_false(result$en_present[1])
  expect_true(is.na(result$en_article[1]))
  expect_true(is.na(result$en_url[1]))

  # Row with article
  expect_true(result$en_present[2])
  expect_equal(result$en_article[2], "Python")
})

test_that("unpack_wikipedia_article_info handles special characters in titles", {
  test_df <- tibble::tibble(
    id = 1,
    wikipedia_articles = list(
      c("en: C++", "es: Río Grande")
    )
  )

  result <- unpack_wikipedia_article_info(test_df, langs = c("en", "es"))

  expect_equal(result$en_article[1], "C++")
  expect_equal(result$es_article[1], "Río Grande")
  # URLs should have spaces replaced
  expect_equal(result$en_url[1], "https://en.wikipedia.org/wiki/C++")
  expect_equal(result$es_url[1], "https://es.wikipedia.org/wiki/Río_Grande")
})

test_that("unpack_wikipedia_article_info handles default language parameter", {
  test_df <- tibble::tibble(
    id = 1,
    wikipedia_articles = list(
      c("en: Python", "es: Pitón")
    )
  )

  # Default should be c("en", "es")
  result <- unpack_wikipedia_article_info(test_df)

  expect_true("en_present" %in% names(result))
  expect_true("es_present" %in% names(result))
  expect_equal(result$en_article[1], "Python")
  expect_equal(result$es_article[1], "Pitón")
})
