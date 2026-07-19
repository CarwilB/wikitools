# Tests for wiki-refs.R
#
# extract_refs_from_wikitext() and all internal helper functions are tested
# using real Wikipedia wikitext loaded from httptest fixtures (no internet
# required). Fixtures were captured from:
#   Mark Twain     -> en.wikipedia.org/w/api.php-a528c5.json
#   Ada Lovelace   -> en.wikipedia.org/w/api.php-b2a116.json
#   Steve Biko     -> en.wikipedia.org/w/api.php-d3b04d.json

library(httptest)

# Load wikitext from frozen fixtures at file-source time.
# All subsequent test_that() blocks reference these objects.
with_mock_dir(".", {
  wt_twain <- get_wikitext_by_name("Mark Twain")
  wt_ada   <- get_wikitext_by_name("Ada Lovelace")
  wt_biko  <- get_wikitext_by_name("Steve Biko")
})

# Expected column order from extract_refs_from_wikitext()
.expected_cols <- c(
  "itemType", "title", "first_author", "creators",
  "date", "year", "publisher", "place", "publicationTitle",
  "volume", "issue", "pages", "ISBN", "ISSN", "DOI", "url",
  "language", "edition", "series", "accessDate",
  "bookTitle", "chapter", ".template_name", ".raw_template"
)

.valid_item_types <- c(
  "book", "bookSection", "journalArticle", "webpage", "newspaperArticle",
  "encyclopediaArticle", "magazineArticle", "thesis", "conferencePaper",
  "report", "videoRecording", "document"
)

# ===========================================================================
# extract_refs_from_wikitext() — output structure
# ===========================================================================

test_that("extract_refs_from_wikitext returns a tibble", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_s3_class(refs, "tbl_df")
})

test_that("extract_refs_from_wikitext has the expected columns in the expected order", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_equal(names(refs), .expected_cols)
})

test_that("extract_refs_from_wikitext creators column is a list of tibbles", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_type(refs$creators, "list")
  first <- refs$creators[[1]]
  expect_s3_class(first, "tbl_df")
  expect_named(first, c("creatorType", "lastName", "firstName"))
})

test_that("extract_refs_from_wikitext first_author is a character vector", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_type(refs$first_author, "character")
})

test_that("extract_refs_from_wikitext itemType has no NAs", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_false(any(is.na(refs$itemType)))
})

test_that("extract_refs_from_wikitext itemType values are all recognised types", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_true(all(refs$itemType %in% .valid_item_types))
})

test_that("extract_refs_from_wikitext non-NA year values are 4-character strings", {
  refs <- extract_refs_from_wikitext(wt_biko)
  years_with_values <- refs$year[!is.na(refs$year)]
  expect_true(all(nchar(years_with_values) == 4L))
  expect_true(all(grepl("^\\d{4}$", years_with_values)))
})

test_that("extract_refs_from_wikitext .raw_template matches citation template syntax", {
  refs <- extract_refs_from_wikitext(wt_biko)
  cite_rows <- refs[refs$.template_name != "bare_ref", ]
  expect_true(all(grepl("^\\{\\{", cite_rows$.raw_template)))
  expect_true(all(grepl("\\}\\}$", cite_rows$.raw_template)))
})

test_that("extract_refs_from_wikitext warns and returns empty tibble when no citations", {
  plain_wikitext <- "This article has no citation templates at all."
  expect_warning(
    result <- extract_refs_from_wikitext(plain_wikitext),
    "No citation templates found"
  )
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 0L)
})

# ===========================================================================
# extract_refs_from_wikitext() — Mark Twain (215 refs)
# ===========================================================================

test_that("extract_refs_from_wikitext returns 215 refs for Mark Twain", {
  refs <- extract_refs_from_wikitext(wt_twain)
  expect_equal(nrow(refs), 215L)
})

test_that("extract_refs_from_wikitext Mark Twain has diverse itemTypes", {
  refs <- extract_refs_from_wikitext(wt_twain)
  types <- unique(refs$itemType)
  expect_true("webpage"          %in% types)
  expect_true("book"             %in% types)
  expect_true("journalArticle"   %in% types)
  expect_true("newspaperArticle" %in% types)
})

test_that("extract_refs_from_wikitext Mark Twain has webpage as most common type", {
  refs <- extract_refs_from_wikitext(wt_twain)
  counts <- table(refs$itemType)
  expect_equal(names(which.max(counts)), "webpage")
})

test_that("extract_refs_from_wikitext Mark Twain has 34 ISBN refs", {
  refs <- extract_refs_from_wikitext(wt_twain)
  expect_equal(sum(!is.na(refs$ISBN)), 34L)
})

test_that("extract_refs_from_wikitext Mark Twain has 15 DOI refs", {
  refs <- extract_refs_from_wikitext(wt_twain)
  expect_equal(sum(!is.na(refs$DOI)), 15L)
})

test_that("extract_refs_from_wikitext Mark Twain has document-type bare refs", {
  refs <- extract_refs_from_wikitext(wt_twain)
  expect_true("document" %in% refs$itemType)
  expect_true(any(refs$.template_name == "bare_ref"))
})

test_that("extract_refs_from_wikitext Mark Twain first_authors include 'Twain, Mark'", {
  refs <- extract_refs_from_wikitext(wt_twain)
  expect_true("Twain, Mark" %in% refs$first_author)
})

# ===========================================================================
# extract_refs_from_wikitext() — Ada Lovelace (168 refs)
# ===========================================================================

test_that("extract_refs_from_wikitext returns 168 refs for Ada Lovelace", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_equal(nrow(refs), 168L)
})

test_that("extract_refs_from_wikitext Ada Lovelace has 23 ISBN refs", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_equal(sum(!is.na(refs$ISBN)), 23L)
})

test_that("extract_refs_from_wikitext Ada Lovelace has 12 DOI refs", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_equal(sum(!is.na(refs$DOI)), 12L)
})

test_that("extract_refs_from_wikitext Ada Lovelace includes book and journal refs", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_true("book"           %in% refs$itemType)
  expect_true("journalArticle" %in% refs$itemType)
})

test_that("extract_refs_from_wikitext Ada Lovelace has videoRecording type", {
  refs <- extract_refs_from_wikitext(wt_ada)
  expect_true("videoRecording" %in% refs$itemType)
})

test_that("extract_refs_from_wikitext Ada Lovelace all creators tibbles have correct columns", {
  refs <- extract_refs_from_wikitext(wt_ada)
  col_check <- vapply(refs$creators, function(cr) {
    setequal(names(cr), c("creatorType", "lastName", "firstName"))
  }, logical(1))
  expect_true(all(col_check))
})

# ===========================================================================
# extract_refs_from_wikitext() — Steve Biko (49 refs)
# ===========================================================================

test_that("extract_refs_from_wikitext returns 49 refs for Steve Biko", {
  refs <- extract_refs_from_wikitext(wt_biko)
  expect_equal(nrow(refs), 49L)
})

test_that("extract_refs_from_wikitext Steve Biko has 18 ISBN refs", {
  refs <- extract_refs_from_wikitext(wt_biko)
  expect_equal(sum(!is.na(refs$ISBN)), 18L)
})

test_that("extract_refs_from_wikitext Steve Biko has encyclopediaArticle type", {
  refs <- extract_refs_from_wikitext(wt_biko)
  expect_true("encyclopediaArticle" %in% refs$itemType)
})

test_that("extract_refs_from_wikitext Steve Biko has only 2 NA years", {
  refs <- extract_refs_from_wikitext(wt_biko)
  expect_equal(sum(is.na(refs$year)), 2L)
})

test_that("extract_refs_from_wikitext Steve Biko first_author is populated for most refs", {
  refs <- extract_refs_from_wikitext(wt_biko)
  pct_with_author <- mean(!is.na(refs$first_author))
  expect_gt(pct_with_author, 0.8)
})

# ===========================================================================
# find_template_end() — internal
# ===========================================================================

test_that("find_template_end extracts exactly the outer template for a simple case", {
  # end_pos is an inclusive endpoint for use with substr()
  text  <- "{{cite book|title=Foo}}"
  end   <- find_template_end(text, 1L)
  extracted <- substr(text, 1L, end)
  expect_equal(extracted, text)
})

test_that("find_template_end extracts the full outer template when nested templates present", {
  text  <- "{{cite book|publisher={{publisher name}}}}"
  end   <- find_template_end(text, 1L)
  extracted <- substr(text, 1L, end)
  expect_equal(extracted, text)
})

test_that("find_template_end returns NA for unmatched opening braces", {
  text <- "{{cite book|title=Foo"
  end  <- find_template_end(text, 1L)
  expect_true(is.na(end))
})

test_that("find_template_end extracts the correct template at a non-zero start offset", {
  text      <- "prefix {{cite book|title=Bar}} suffix"
  end       <- find_template_end(text, 8L)
  extracted <- substr(text, 8L, end)
  expect_equal(extracted, "{{cite book|title=Bar}}")
})

# ===========================================================================
# parse_template_params() — internal
# ===========================================================================

test_that("parse_template_params extracts .template as lowercased name", {
  tmpl   <- "{{Cite Book|title=Foo|year=2000}}"
  params <- parse_template_params(tmpl)
  expect_equal(params$.template, "cite book")
})

test_that("parse_template_params extracts named parameters", {
  tmpl   <- "{{cite book|title=A History|author=Smith|year=2001}}"
  params <- parse_template_params(tmpl)
  expect_equal(params$title, "A History")
  expect_equal(params$author, "Smith")
  expect_equal(params$year, "2001")
})

test_that("parse_template_params handles pipes inside nested templates", {
  # The | inside {{lang|en|text}} should not split the outer template
  tmpl   <- "{{cite book|title={{lang|en|The Title}}|year=1999}}"
  params <- parse_template_params(tmpl)
  expect_equal(params$.template, "cite book")
  expect_true(!is.null(params$year))
  expect_equal(params$year, "1999")
})

test_that("parse_template_params stores positional args as .unnamed_N", {
  tmpl   <- "{{cite book|Positional value}}"
  params <- parse_template_params(tmpl)
  expect_true(".unnamed_1" %in% names(params))
})

test_that("parse_template_params lowercases parameter keys", {
  tmpl   <- "{{cite book|Title=Foo|Year=2000}}"
  params <- parse_template_params(tmpl)
  expect_true("title" %in% names(params))
  expect_true("year"  %in% names(params))
  expect_false("Title" %in% names(params))
})

# ===========================================================================
# clean_wiki() — internal
# ===========================================================================

test_that("clean_wiki returns NA for NULL input", {
  expect_identical(clean_wiki(NULL), NA_character_)
})

test_that("clean_wiki returns NA for empty or whitespace-only string", {
  expect_identical(clean_wiki(""), NA_character_)
  expect_identical(clean_wiki("   "), NA_character_)
})

test_that("clean_wiki strips piped wikilink and returns display text", {
  expect_equal(clean_wiki("[[Bolivia|the country]]"), "the country")
})

test_that("clean_wiki strips simple wikilink and returns the link target", {
  expect_equal(clean_wiki("[[Bolivia]]"), "Bolivia")
})

test_that("clean_wiki removes italic markup", {
  expect_equal(clean_wiki("''italic text''"), "italic text")
})

test_that("clean_wiki expands {{!}} to a pipe character", {
  expect_equal(clean_wiki("a{{!}}b"), "a|b")
})

test_that("clean_wiki removes simple valueless templates", {
  result <- clean_wiki("text {{ndash}} more")
  expect_false(grepl("\\{\\{", result))
  expect_false(grepl("ndash", result))
})

test_that("clean_wiki handles one-argument templates by returning the argument", {
  result <- clean_wiki("{{lang|French text}}")
  expect_equal(result, "French text")
})

# ===========================================================================
# template_to_itemtype() — internal
# ===========================================================================

test_that("template_to_itemtype maps cite book to book", {
  expect_equal(template_to_itemtype("cite book"), "book")
})

test_that("template_to_itemtype maps cite journal to journalArticle", {
  expect_equal(template_to_itemtype("cite journal"), "journalArticle")
})

test_that("template_to_itemtype maps cite web to webpage", {
  expect_equal(template_to_itemtype("cite web"), "webpage")
})

test_that("template_to_itemtype maps cite news to newspaperArticle", {
  expect_equal(template_to_itemtype("cite news"), "newspaperArticle")
})

test_that("template_to_itemtype maps cite encyclopedia to encyclopediaArticle", {
  expect_equal(template_to_itemtype("cite encyclopedia"), "encyclopediaArticle")
})

test_that("template_to_itemtype maps cite thesis to thesis", {
  expect_equal(template_to_itemtype("cite thesis"), "thesis")
})

test_that("template_to_itemtype maps cite magazine to magazineArticle", {
  expect_equal(template_to_itemtype("cite magazine"), "magazineArticle")
})

test_that("template_to_itemtype maps cite report to report", {
  expect_equal(template_to_itemtype("cite report"), "report")
})

test_that("template_to_itemtype maps harvc to bookSection", {
  expect_equal(template_to_itemtype("harvc"), "bookSection")
})

test_that("template_to_itemtype maps citation to book by default", {
  expect_equal(template_to_itemtype("citation"), "book")
})

test_that("template_to_itemtype maps citation with journal param to journalArticle", {
  expect_equal(
    template_to_itemtype("citation", params = list(journal = "Nature")),
    "journalArticle"
  )
})

test_that("template_to_itemtype is case-insensitive", {
  expect_equal(template_to_itemtype("Cite Book"), "book")
  expect_equal(template_to_itemtype("CITE WEB"),  "webpage")
})

test_that("template_to_itemtype returns document for unrecognised template", {
  expect_equal(template_to_itemtype("cite something_unknown_xyz"), "document")
})

# ===========================================================================
# extract_bare_refs() — internal
# ===========================================================================

test_that("extract_bare_refs returns character(0) when no <ref> tags present", {
  result <- extract_bare_refs("No refs here at all.")
  expect_equal(result, character(0))
})

test_that("extract_bare_refs extracts simple bare text refs", {
  wt <- "Text.<ref>Some plain note without a template.</ref> More."
  result <- extract_bare_refs(wt)
  expect_length(result, 1L)
  expect_true(grepl("plain note", result))
})

test_that("extract_bare_refs excludes refs that contain a cite template", {
  wt <- "<ref>{{cite book|title=Foo}}</ref>"
  result <- extract_bare_refs(wt)
  expect_equal(result, character(0))
})

test_that("extract_bare_refs handles mixed cite and bare refs correctly", {
  wt <- "<ref>{{cite book|title=Foo}}</ref> text <ref>Just a note.</ref>"
  result <- extract_bare_refs(wt)
  expect_length(result, 1L)
  expect_true(grepl("Just a note", result))
})

test_that("extract_bare_refs returns character vector", {
  result <- extract_bare_refs(wt_biko)
  expect_type(result, "character")
})

# ===========================================================================
# extract_authors() — internal
# ===========================================================================

test_that("extract_authors returns tibble with expected columns", {
  params <- list(.template = "cite book", last = "Smith", first = "John")
  result <- extract_authors(params)
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("creatorType", "lastName", "firstName"))
})

test_that("extract_authors extracts a single last/first pair as author", {
  params <- list(.template = "cite book", last = "Orwell", first = "George")
  result <- extract_authors(params)
  expect_equal(nrow(result), 1L)
  expect_equal(result$creatorType[1], "author")
  expect_equal(result$lastName[1],   "Orwell")
  expect_equal(result$firstName[1],  "George")
})

test_that("extract_authors extracts multiple numbered author pairs", {
  params <- list(
    .template = "cite book",
    last1 = "Smith", first1 = "John",
    last2 = "Jones", first2 = "Mary"
  )
  result <- extract_authors(params)
  expect_equal(nrow(result), 2L)
  expect_equal(result$lastName, c("Smith", "Jones"))
})

test_that("extract_authors splits 'Last, First' author= string on comma", {
  params <- list(.template = "cite book", author = "Twain, Mark")
  result <- extract_authors(params)
  expect_equal(nrow(result), 1L)
  expect_equal(result$lastName[1],  "Twain")
  expect_equal(result$firstName[1], "Mark")
})

test_that("extract_authors stores single-name author= without comma split", {
  params <- list(.template = "cite book", author = "UNESCO")
  result <- extract_authors(params)
  expect_equal(nrow(result), 1L)
  expect_equal(result$lastName[1], "UNESCO")
  expect_equal(result$firstName[1], "")
})

test_that("extract_authors returns default empty author row when no author info", {
  params <- list(.template = "cite book", title = "No Author Book")
  result <- extract_authors(params)
  expect_equal(nrow(result), 1L)
  expect_equal(result$creatorType[1], "author")
  expect_equal(result$lastName[1],    "")
  expect_equal(result$firstName[1],   "")
})

test_that("extract_authors handles author= param that is NA without error", {
  # Regression: clean_wiki() can return NA; str_detect(NA, ...) must not error
  params <- list(.template = "cite book", author = NA_character_)
  expect_no_error(extract_authors(params))
})
