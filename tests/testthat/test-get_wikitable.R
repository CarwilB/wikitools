# Tests for get_wikitable() and its internal helpers.
#
# The end-to-end tests mock httr::GET()/httr::content()/httr::status_code()
# to serve a saved copy of the real page
# (tests/testthat/fixtures/beatles_albums_discography.html, captured from
# https://en.wikipedia.org/wiki/The_Beatles_albums_discography), so no live
# network access is required. Unit tests of the internal parsing helpers use
# small hand-built HTML snippets instead.

library(rvest)

# ===========================================================================
# Internal helpers — small synthetic HTML
# ===========================================================================

test_that(".cell_span defaults to 1 when the attribute is absent", {
  page  <- read_html("<table><tr><td>a</td><td colspan='3'>b</td></tr></table>")
  cells <- html_elements(page, "td")
  expect_equal(.cell_span(cells, "colspan"), c(1L, 3L))
})

test_that(".cell_text strips numeric and single-letter citation markers", {
  page  <- read_html("<table><tr><th>UK[8][9]</th><th>Notes[A]</th></tr></table>")
  cells <- html_elements(page, "th")
  expect_equal(.cell_text(cells), c("UK", "Notes"))
})

test_that(".cell_text preserves citation markers when strip_citations = FALSE", {
  page  <- read_html("<table><tr><th>UK[8]</th></tr></table>")
  cells <- html_elements(page, "th")
  expect_equal(.cell_text(cells, strip_citations = FALSE), "UK[8]")
})

test_that(".merge_two_header_rows merges rowspan and colspan cells correctly", {
  page <- read_html(paste0(
    "<table>",
    "<tr><th rowspan='2'>Title</th><th colspan='2'>Chart positions</th></tr>",
    "<tr><th>UK</th><th>US</th></tr>",
    "</table>"
  ))
  rows <- html_elements(page, "tr")
  row1 <- html_elements(rows[[1]], "th, td")
  row2 <- html_elements(rows[[2]], "th, td")
  expect_equal(.merge_two_header_rows(row1, row2), c("Title", "UK", "US"))
})

test_that(".expand_row repeats colspan text and pads short rows with NA", {
  page  <- read_html("<table><tr><td colspan='2'>x</td></tr></table>")
  cells <- html_elements(page, "td")
  expect_equal(.expand_row(cells, total_cols = 4), c("x", "x", NA_character_, NA_character_))
})

test_that(".expand_row truncates rows longer than total_cols", {
  page  <- read_html("<table><tr><td>a</td><td>b</td><td>c</td></tr></table>")
  cells <- html_elements(page, "td")
  expect_equal(.expand_row(cells, total_cols = 2), c("a", "b"))
})

test_that(".expand_row_links extracts a link only from a th (row-header) cell", {
  page <- read_html(paste0(
    "<table><tr>",
    "<th><a href='https://en.wikipedia.org/wiki/Foo'>Foo</a></th>",
    "<td><a href='https://en.wikipedia.org/wiki/Bar'>Bar</a></td>",
    "</tr></table>"
  ))
  cells <- html_elements(html_element(page, "tr"), "th, td")
  expect_equal(
    .expand_row_links(cells, total_cols = 2),
    c("https://en.wikipedia.org/wiki/Foo", NA_character_)
  )
})

test_that(".expand_row_links returns NA for a th cell with no link", {
  page  <- read_html("<table><tr><th>Plain text</th></tr></table>")
  cells <- html_elements(html_element(page, "tr"), "th, td")
  expect_equal(.expand_row_links(cells, total_cols = 1), NA_character_)
})

test_that(".expand_row_links ignores non-wiki links (e.g. citation anchors)", {
  page <- read_html(paste0(
    "<table><tr><th>Foo<a href='#cite_note-1'>[1]</a></th></tr></table>"
  ))
  cells <- html_elements(html_element(page, "tr"), "th, td")
  expect_equal(.expand_row_links(cells, total_cols = 1), NA_character_)
})

test_that(".expand_row_links converts a relative href to an absolute URL using lang", {
  page  <- read_html("<table><tr><th><a href='/wiki/Foo'>Foo</a></th></tr></table>")
  cells <- html_elements(html_element(page, "tr"), "th, td")
  expect_equal(
    .expand_row_links(cells, total_cols = 1, lang = "fr"),
    "https://fr.wikipedia.org/wiki/Foo"
  )
})

test_that(".parse_wikitable_node handles a simple single-header-row table", {
  page <- read_html(paste0(
    "<table class='wikitable'><caption>Simple</caption>",
    "<tr><th>Name</th><th>Value</th></tr>",
    "<tr><td>A</td><td>1</td></tr>",
    "<tr><td>B</td><td>2</td></tr>",
    "</table>"
  ))
  node   <- html_element(page, "table")
  result <- .parse_wikitable_node(node)

  expect_equal(names(result$data), c("Name", "Value"))
  expect_equal(nrow(result$data), 2)
  expect_equal(result$data$Name, c("A", "B"))
  expect_equal(result$notes, character(0))
})

test_that(".parse_wikitable_node separates a single-cell footnote row into notes", {
  page <- read_html(paste0(
    "<table class='wikitable'>",
    "<tr><th>Name</th><th>Value</th></tr>",
    "<tr><td>A</td><td>1</td></tr>",
    "<tr><td colspan='2'>Legend: explains a symbol.</td></tr>",
    "</table>"
  ))
  node   <- html_element(page, "table")
  result <- .parse_wikitable_node(node, drop_notes = TRUE)

  expect_equal(nrow(result$data), 1)
  expect_equal(result$notes, "Legend: explains a symbol.")
})

test_that(".parse_wikitable_node keeps the footnote row when drop_notes = FALSE", {
  page <- read_html(paste0(
    "<table class='wikitable'>",
    "<tr><th>Name</th><th>Value</th></tr>",
    "<tr><td>A</td><td>1</td></tr>",
    "<tr><td colspan='2'>Legend text</td></tr>",
    "</table>"
  ))
  node   <- html_element(page, "table")
  result <- .parse_wikitable_node(node, drop_notes = FALSE)

  expect_equal(nrow(result$data), 2)
  expect_equal(result$notes, character(0))
  expect_equal(result$data$Value[2], "Legend text")
})

test_that(".parse_wikitable_node adds a `<name>_link` column after a linked row-header", {
  page <- read_html(paste0(
    "<table class='wikitable'>",
    "<tr><th>Title</th><th>Value</th></tr>",
    "<tr><th scope='row'><a href='https://en.wikipedia.org/wiki/Foo'>Foo</a></th><td>1</td></tr>",
    "<tr><th scope='row'><a href='https://en.wikipedia.org/wiki/Bar'>Bar</a></th><td>2</td></tr>",
    "</table>"
  ))
  node   <- html_element(page, "table")
  result <- .parse_wikitable_node(node, extract_links = TRUE)

  expect_equal(names(result$data), c("Title", "Title_link", "Value"))
  expect_equal(result$data$Title_link, c(
    "https://en.wikipedia.org/wiki/Foo", "https://en.wikipedia.org/wiki/Bar"
  ))
})

test_that(".parse_wikitable_node does not add a link column for a td-only (non-row-header) column", {
  page <- read_html(paste0(
    "<table class='wikitable'>",
    "<tr><th>Title</th><th>Details</th></tr>",
    "<tr><td><a href='https://en.wikipedia.org/wiki/Foo'>Foo</a></td>",
    "<td><a href='https://en.wikipedia.org/wiki/Label'>Label link</a></td></tr>",
    "</table>"
  ))
  node   <- html_element(page, "table")
  result <- .parse_wikitable_node(node, extract_links = TRUE)

  expect_equal(names(result$data), c("Title", "Details"))
})

test_that(".parse_wikitable_node omits link columns entirely when extract_links = FALSE", {
  page <- read_html(paste0(
    "<table class='wikitable'>",
    "<tr><th>Title</th><th>Value</th></tr>",
    "<tr><th scope='row'><a href='https://en.wikipedia.org/wiki/Foo'>Foo</a></th><td>1</td></tr>",
    "</table>"
  ))
  node   <- html_element(page, "table")
  result <- .parse_wikitable_node(node, extract_links = FALSE)

  expect_equal(names(result$data), c("Title", "Value"))
})

test_that(".parse_wikitable_node falls back to html_table() for 3+ header rows", {
  page <- read_html(paste0(
    "<table class='wikitable'>",
    "<tr><th>A</th></tr>",
    "<tr><th>B</th></tr>",
    "<tr><th>C</th></tr>",
    "<tr><td>1</td></tr>",
    "</table>"
  ))
  node <- html_element(page, "table")
  expect_message(result <- .parse_wikitable_node(node), "falling back")
  expect_true(is.data.frame(result$data))
})

test_that(".parse_wikitable_node returns an empty tibble for a table with no rows", {
  page   <- read_html("<table class='wikitable'></table>")
  node   <- html_element(page, "table")
  result <- .parse_wikitable_node(node)
  expect_equal(nrow(result$data), 0)
  expect_equal(result$notes, character(0))
})

# ===========================================================================
# get_wikitable() — end-to-end via a mocked fixture page
# ===========================================================================

mock_beatles_page <- function() {
  paste(
    readLines(test_path("fixtures/beatles_albums_discography.html"), warn = FALSE),
    collapse = "\n"
  )
}

with_beatles_mock <- function(code) {
  local_mocked_bindings(
    GET         = function(...) structure(list(status_code = 200L), class = "response"),
    status_code = function(...) 200L,
    content     = function(...) mock_beatles_page(),
    .package    = "httr"
  )
  force(code)
}

test_that("get_wikitable retrieves the studio albums table by caption match", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 12)
  expect_true(all(c("Title", "Album details", "UK", "AUS", "Certifications", "Sales") %in% names(result)))
})

test_that("get_wikitable sets the caption, url, and notes attributes", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )

  expect_equal(
    attr(result, "caption"),
    "List of studio albums, with selected chart positions and certification"
  )
  expect_equal(attr(result, "url"), "https://en.wikipedia.org/wiki/The_Beatles_albums_discography")
  expect_length(attr(result, "notes"), 1)
  expect_match(attr(result, "notes"), "denotes that the recording did not chart")
})

test_that("get_wikitable's first row is real data, not a repeated sub-header", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )
  expect_equal(result$Title[1], "Please Please Me")
  expect_equal(result$UK[1], "1")
})

test_that("get_wikitable strips citation markers from column names by default", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )
  expect_false(any(grepl("\\[", names(result))))
})

test_that("get_wikitable keeps citation markers when strip_citations = FALSE", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification",
      strip_citations = FALSE
    )
  )
  expect_true(any(grepl("\\[", names(result))))
})

test_that("get_wikitable errors with the list of available captions when match fails", {
  err <- tryCatch(
    with_beatles_mock(
      get_wikitable("The Beatles albums discography", match = "not a real caption at all")
    ),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  expect_match(conditionMessage(err), "List of studio albums")
})

test_that("get_wikitable uses the first matching caption (with a message) when match is ambiguous", {
  # Both "List of studio albums..." captions on the page contain "studio albums"
  expect_message(
    result <- with_beatles_mock(
      get_wikitable("The Beatles albums discography", match = "studio albums")
    ),
    "Multiple table captions matched"
  )
  expect_equal(
    attr(result, "caption"),
    "List of studio albums, with selected chart positions and certification"
  )
})

test_that("get_wikitable falls back to index when match is NULL", {
  result <- with_beatles_mock(
    get_wikitable("The Beatles albums discography", index = 2)
  )
  expect_equal(
    attr(result, "caption"),
    "List of studio albums with selected chart positions and certification"
  )
})

test_that("get_wikitable errors when index exceeds the number of wikitables found", {
  expect_error(
    with_beatles_mock(
      get_wikitable("The Beatles albums discography", index = 999)
    ),
    "exceeds"
  )
})

test_that("get_wikitable errors on an HTTP failure status", {
  local_mocked_bindings(
    GET         = function(...) structure(list(status_code = 404L), class = "response"),
    status_code = function(...) 404L,
    .package    = "httr"
  )
  expect_error(get_wikitable("Does Not Exist"), "Failed to fetch page")
})

test_that("get_wikitable errors when the page has no wikitable-class tables", {
  local_mocked_bindings(
    GET         = function(...) structure(list(status_code = 200L), class = "response"),
    status_code = function(...) 200L,
    content     = function(...) "<html><body><p>No tables here.</p></body></html>",
    .package    = "httr"
  )
  expect_error(get_wikitable("No Tables Page"), "No wikitable-class tables")
})

# ===========================================================================
# get_wikitable() — link extraction (extract_links)
# ===========================================================================

test_that("get_wikitable adds a Title_link column immediately after Title by default", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )
  expect_equal(names(result)[1:2], c("Title", "Title_link"))
  expect_match(result$Title_link[1], "^https://en\\.wikipedia\\.org/wiki/")
  expect_true(grepl("Please_Please_Me", result$Title_link[1], fixed = TRUE))
})

test_that("get_wikitable does not add a link column for Album details, Certifications, or Sales", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )
  expect_false("Album details_link" %in% names(result))
  expect_false("Certifications_link" %in% names(result))
  expect_false("Sales_link" %in% names(result))
})

test_that("get_wikitable omits Title_link entirely when extract_links = FALSE", {
  result <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification",
      extract_links = FALSE
    )
  )
  expect_false("Title_link" %in% names(result))
  expect_true("Title" %in% names(result))
})

# ===========================================================================
# clean_column_headers()
# ===========================================================================

test_that("clean_column_headers lower-cases plain words and joins multi-word headers with _", {
  df <- tibble::tibble(Title = 1, `Album details` = 2)
  df <- clean_column_headers(df)
  expect_equal(names(df), c("title", "album_details"))
})

test_that("clean_column_headers preserves all-caps acronyms", {
  df <- tibble::tibble(UK = 1, AUS = 2)
  df <- clean_column_headers(df)
  expect_equal(names(df), c("UK", "AUS"))
})

test_that("clean_column_headers replaces an existing underscore-joined suffix consistently", {
  df <- tibble::tibble(Title_link = 1)
  df <- clean_column_headers(df)
  expect_equal(names(df), "title_link")
})

test_that("clean_column_headers strips footnote markers from headers", {
  df <- tibble::tibble(`Album details[A]` = 1, `UK[8][9]` = 2)
  df <- clean_column_headers(df)
  expect_equal(names(df), c("album_details", "UK"))
})

test_that("clean_column_headers on get_wikitable output produces the expected first five names", {
  albums <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )
  albums <- clean_column_headers(albums)
  expect_equal(
    names(albums)[1:5],
    c("title", "title_link", "album_details", "UK", "AUS")
  )
})

test_that("clean_column_headers preserves data, only renaming columns", {
  df <- tibble::tibble(Name = c("A", "B"), Value = c(1, 2))
  result <- clean_column_headers(df)
  expect_equal(result$name, c("A", "B"))
  expect_equal(result$value, c(1, 2))
})

# ===========================================================================
# link_to_article_name()
# ===========================================================================

test_that("link_to_article_name extracts and de-underscores the article slug", {
  expect_equal(
    link_to_article_name("https://en.wikipedia.org/wiki/Please_Please_Me"),
    "Please Please Me"
  )
})

test_that("link_to_article_name handles a relative /wiki/ href", {
  expect_equal(link_to_article_name("/wiki/Abbey_Road"), "Abbey Road")
})

test_that("link_to_article_name returns NA for non-wiki links", {
  expect_true(is.na(link_to_article_name("https://example.com/not-wiki")))
})

test_that("link_to_article_name returns NA for NA input", {
  expect_true(is.na(link_to_article_name(NA_character_)))
})

test_that("link_to_article_name is vectorized over a mixed vector", {
  result <- link_to_article_name(c(
    "https://en.wikipedia.org/wiki/Help!", NA, "not a link"
  ))
  expect_equal(result, c("Help!", NA_character_, NA_character_))
})

test_that("link_to_article_name composes with get_wikitable output as in the documented example", {
  albums <- with_beatles_mock(
    get_wikitable(
      "The Beatles albums discography",
      match = "List of studio albums, with selected chart positions and certification"
    )
  )
  albums <- clean_column_headers(albums)
  albums <- albums |>
    dplyr::mutate(title_article = link_to_article_name(title_link)) |>
    dplyr::relocate(title_article, .after = title)

  expect_equal(names(albums)[1:3], c("title", "title_article", "title_link"))
  expect_equal(nrow(albums), 12)
  expect_false(any(is.na(albums$title_article)))
  # The linked article title need not equal the display title verbatim --
  # e.g. "Revolver" links to the disambiguated article "Revolver (Beatles album)",
  # and "The Beatles (\"The White Album\")" links to plain "The Beatles (album)".
  expect_equal(albums$title_article[albums$title == "Revolver"], "Revolver (Beatles album)")
})
