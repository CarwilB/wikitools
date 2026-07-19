# Tests for get-wikipedia-text.R — all HTTP calls mocked via httptest
#
# Fixtures are real Wikipedia API responses captured with capture_requests()
# and stored in tests/testthat/en.wikipedia.org/w/api.php-*.json.
#
# Pages captured:
#   get_wikitext_by_name()      : Mark Twain, Ada Lovelace, Steve Biko
#   get_wikitext_by_revid()     : Ada Lovelace, revid 1360639004
#   get_page_info_batch()       : Hydrogen, Helium, Lithium, Boron, Carbon, Nitrogen
#   get_wp_category_members()   : Category:Noble gases (pages and subcategories)
#   get_plain_text()            : Steve Biko (by title), Ada Lovelace (by revid)
#
# with_mock_dir(".") sets the mock path to tests/testthat/, where all fixtures live.

library(httptest)

# ===========================================================================
# get_wikitext_by_name()
# ===========================================================================

with_mock_dir(".", {

  test_that("get_wikitext_by_name returns a character string for Mark Twain", {
    result <- get_wikitext_by_name("Mark Twain")
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_gt(nchar(result), 1000L)
  })

  test_that("get_wikitext_by_name Mark Twain content is plausible wikitext", {
    result <- get_wikitext_by_name("Mark Twain")
    expect_true(grepl("Samuel Langhorne Clemens", result, fixed = TRUE))
    expect_true(grepl("Missouri", result, fixed = TRUE))
    expect_true(grepl("{{Infobox", result, fixed = TRUE))
  })

  test_that("get_wikitext_by_name returns a character string for Ada Lovelace", {
    result <- get_wikitext_by_name("Ada Lovelace")
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_gt(nchar(result), 1000L)
  })

  test_that("get_wikitext_by_name Ada Lovelace content mentions key figures", {
    result <- get_wikitext_by_name("Ada Lovelace")
    expect_true(grepl("Augusta Ada King", result, fixed = TRUE))
    expect_true(grepl("Charles Babbage", result, fixed = TRUE))
  })

  test_that("get_wikitext_by_name returns a character string for Steve Biko", {
    result <- get_wikitext_by_name("Steve Biko")
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_gt(nchar(result), 1000L)
  })

  test_that("get_wikitext_by_name Steve Biko content reflects his biography", {
    result <- get_wikitext_by_name("Steve Biko")
    expect_true(grepl("apartheid", result, ignore.case = TRUE))
    expect_true(grepl("Black Consciousness", result, fixed = TRUE))
    expect_true(grepl("1946", result, fixed = TRUE))
  })

})

# ===========================================================================
# get_wikitext_by_revid()
# ===========================================================================

with_mock_dir(".", {

  test_that("get_wikitext_by_revid returns a character string for Ada Lovelace revid", {
    result <- get_wikitext_by_revid(NA, revision_id = 1360639004)
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_gt(nchar(result), 1000L)
  })

  test_that("get_wikitext_by_revid Ada Lovelace revid content matches by-name content", {
    result_by_revid <- get_wikitext_by_revid(NA, revision_id = 1360639004)
    result_by_name  <- get_wikitext_by_name("Ada Lovelace")
    expect_identical(result_by_revid, result_by_name)
  })

  test_that("get_wikitext_by_revid accepts numeric revision_id", {
    result <- get_wikitext_by_revid(NA, revision_id = 1360639004L)
    expect_type(result, "character")
  })

  test_that("get_wikitext_by_revid accepts string revision_id", {
    result <- get_wikitext_by_revid(NA, revision_id = "1360639004")
    expect_type(result, "character")
  })

})

# ===========================================================================
# get_wikitext_from_url()
# ===========================================================================

with_mock_dir(".", {

  test_that("get_wikitext_from_url dispatches oldid URL to get_wikitext_by_revid", {
    result <- get_wikitext_from_url(
      "https://en.wikipedia.org/w/index.php?title=Ada_Lovelace&oldid=1360639004"
    )
    expect_type(result, "character")
    expect_true(grepl("Augusta Ada King", result, fixed = TRUE))
  })

  test_that("get_wikitext_from_url oldid result matches direct revid fetch", {
    from_url <- get_wikitext_from_url(
      "https://en.wikipedia.org/w/index.php?title=Ada_Lovelace&oldid=1360639004"
    )
    direct <- get_wikitext_by_revid(NA, revision_id = 1360639004)
    expect_identical(from_url, direct)
  })

})

# ===========================================================================
# get_page_info_batch()
# ===========================================================================

with_mock_dir(".", {

  test_that("get_page_info_batch returns a tibble with correct columns", {
    elements <- c("Hydrogen", "Helium", "Lithium", "Boron", "Carbon", "Nitrogen")
    result <- get_page_info_batch(elements)
    expect_s3_class(result, "tbl_df")
    expect_named(result, c("title", "pageid", "page_length", "wikidata_qid"))
  })

  test_that("get_page_info_batch returns one row per input title", {
    elements <- c("Hydrogen", "Helium", "Lithium", "Boron", "Carbon", "Nitrogen")
    result <- get_page_info_batch(elements)
    expect_equal(nrow(result), 6L)
  })

  test_that("get_page_info_batch returns correct Wikidata QIDs for elements", {
    elements <- c("Hydrogen", "Helium", "Lithium", "Boron", "Carbon", "Nitrogen")
    result <- get_page_info_batch(elements)
    expect_equal(result$wikidata_qid[result$title == "Hydrogen"], "Q556")
    expect_equal(result$wikidata_qid[result$title == "Helium"],   "Q560")
    expect_equal(result$wikidata_qid[result$title == "Lithium"],  "Q568")
    expect_equal(result$wikidata_qid[result$title == "Boron"],    "Q618")
    expect_equal(result$wikidata_qid[result$title == "Carbon"],   "Q623")
    expect_equal(result$wikidata_qid[result$title == "Nitrogen"], "Q627")
  })

  test_that("get_page_info_batch returns correct pageids for elements", {
    elements <- c("Hydrogen", "Helium", "Lithium", "Boron", "Carbon", "Nitrogen")
    result <- get_page_info_batch(elements)
    expect_equal(result$pageid[result$title == "Hydrogen"], 13255L)
    expect_equal(result$pageid[result$title == "Helium"],   13256L)
    expect_equal(result$pageid[result$title == "Boron"],     3755L)
  })

  test_that("get_page_info_batch pageid and page_length columns are numeric", {
    elements <- c("Hydrogen", "Helium", "Lithium", "Boron", "Carbon", "Nitrogen")
    result <- get_page_info_batch(elements)
    expect_true(is.numeric(result$pageid))
    expect_true(is.numeric(result$page_length))
  })

})

# ===========================================================================
# get_wp_category_members()
# ===========================================================================

with_mock_dir(".", {

  test_that("get_wp_category_members returns a tibble with correct columns", {
    result <- get_wp_category_members("Category:Noble gases")
    expect_s3_class(result, "tbl_df")
    expect_named(result, c("pageid", "ns", "title"))
  })

  test_that("get_wp_category_members returns 14 pages for Category:Noble gases", {
    result <- get_wp_category_members("Category:Noble gases")
    expect_equal(nrow(result), 14L)
  })

  test_that("get_wp_category_members pages are all in article namespace (ns = 0)", {
    result <- get_wp_category_members("Category:Noble gases")
    expect_true(all(result$ns == 0L))
  })

  test_that("get_wp_category_members includes expected noble gas articles", {
    result <- get_wp_category_members("Category:Noble gases")
    expect_true("Helium"   %in% result$title)
    expect_true("Neon"     %in% result$title)
    expect_true("Argon"    %in% result$title)
    expect_true("Xenon"    %in% result$title)
    expect_true("Radon"    %in% result$title)
    expect_true("Noble gas" %in% result$title)
  })

  test_that("get_wp_category_members adds 'Category:' prefix automatically", {
    with_prefix    <- get_wp_category_members("Category:Noble gases")
    without_prefix <- get_wp_category_members("Noble gases")
    expect_identical(with_prefix, without_prefix)
  })

  test_that("get_wp_category_members type='subcat' returns 8 subcategories", {
    result <- get_wp_category_members("Category:Noble gases", type = "subcat")
    expect_equal(nrow(result), 8L)
  })

  test_that("get_wp_category_members subcategories are in category namespace (ns = 14)", {
    result <- get_wp_category_members("Category:Noble gases", type = "subcat")
    expect_true(all(result$ns == 14L))
  })

  test_that("get_wp_category_members subcategories have Category: prefix in titles", {
    result <- get_wp_category_members("Category:Noble gases", type = "subcat")
    expect_true(all(grepl("^Category:", result$title)))
  })

  test_that("get_wp_category_members subcategories include expected entries", {
    result <- get_wp_category_members("Category:Noble gases", type = "subcat")
    expect_true("Category:Helium" %in% result$title)
    expect_true("Category:Neon"   %in% result$title)
    expect_true("Category:Argon"  %in% result$title)
    expect_true("Category:Xenon"  %in% result$title)
  })

})

# ===========================================================================
# get_wp_subcategories()
# ===========================================================================

with_mock_dir(".", {

  test_that("get_wp_subcategories returns only subcategories", {
    result <- get_wp_subcategories("Category:Noble gases")
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 8L)
    expect_true(all(result$ns == 14L))
  })

  test_that("get_wp_subcategories matches category_members with type='subcat'", {
    subs     <- get_wp_subcategories("Category:Noble gases")
    from_mem <- get_wp_category_members("Category:Noble gases", type = "subcat")
    expect_identical(subs, from_mem)
  })

})

# ===========================================================================
# get_wp_category_pages()
# ===========================================================================

with_mock_dir(".", {

  test_that("get_wp_category_pages returns only article pages", {
    result <- get_wp_category_pages("Category:Noble gases")
    expect_s3_class(result, "tbl_df")
    expect_equal(nrow(result), 14L)
    expect_true(all(result$ns == 0L))
  })

  test_that("get_wp_category_pages matches category_members with type='page'", {
    pages    <- get_wp_category_pages("Category:Noble gases")
    from_mem <- get_wp_category_members("Category:Noble gases", type = "page")
    expect_identical(pages, from_mem)
  })

})

# ===========================================================================
# cache_wikitext()
# ===========================================================================

test_that("cache_wikitext returns cached content without an API call", {
  tmp <- withr::local_tempdir()
  # Pre-populate the cache with synthetic content
  writeLines("== Cached wikitext ==\nSome pre-cached content.", file.path(tmp, "Mark Twain.txt"))

  # Should read from cache; any real or mocked HTTP call would return different content
  expect_no_request({
    result <- cache_wikitext("Mark Twain", cache_dir = tmp)
  })
  expect_type(result, "character")
  expect_true(grepl("pre-cached content", result, fixed = TRUE))
})

with_mock_dir(".", {

  test_that("cache_wikitext fetches and writes wikitext on cache miss", {
    tmp <- withr::local_tempdir()
    result <- cache_wikitext("Mark Twain", cache_dir = tmp)
    expect_type(result, "character")
    expect_gt(nchar(result), 1000L)
    expect_true(file.exists(file.path(tmp, "Mark Twain.txt")))
  })

  test_that("cache_wikitext written file has same content as returned string", {
    tmp <- withr::local_tempdir()
    result   <- cache_wikitext("Mark Twain", cache_dir = tmp)
    on_disk  <- paste(readLines(file.path(tmp, "Mark Twain.txt"), warn = FALSE),
                      collapse = "\n")
    expect_identical(result, on_disk)
  })

  test_that("cache_wikitext safe_name replaces special characters in file name", {
    tmp <- withr::local_tempdir()
    # Colon is a special character that should be replaced with underscore
    result <- cache_wikitext("Ada Lovelace", cache_dir = tmp)
    expect_true(file.exists(file.path(tmp, "Ada Lovelace.txt")))
  })

})

# ===========================================================================
# get_plain_text()
# ===========================================================================

test_that("get_plain_text errors when both title and revision_id are NULL", {
  expect_error(
    get_plain_text(title = NULL, revision_id = NULL),
    "You must provide either a title or a revision_id"
  )
})

with_mock_dir(".", {

  test_that("get_plain_text by title returns a character string for Steve Biko", {
    result <- get_plain_text("Steve Biko")
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_gt(nchar(result), 1000L)
  })

  test_that("get_plain_text Steve Biko content mentions anti-apartheid", {
    result <- get_plain_text("Steve Biko")
    expect_true(grepl("anti-apartheid", result, ignore.case = TRUE))
  })

  test_that("get_plain_text Steve Biko plain text contains no wikitext markup", {
    result <- get_plain_text("Steve Biko")
    expect_false(grepl("{{", result, fixed = TRUE))
    expect_false(grepl("[[", result, fixed = TRUE))
    expect_false(grepl("<ref", result, fixed = TRUE))
  })

  test_that("get_plain_text by revision_id returns a character string", {
    result <- get_plain_text(revision_id = 1360639004)
    expect_type(result, "character")
    expect_length(result, 1L)
    expect_gt(nchar(result), 1000L)
  })

  test_that("get_plain_text Ada Lovelace by revid mentions Babbage", {
    result <- get_plain_text(revision_id = 1360639004)
    expect_true(grepl("Babbage", result, fixed = TRUE))
  })

})
