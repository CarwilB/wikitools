# get_wikitable.R
# Retrieval of rendered HTML tables (`class="wikitable"`) from Wikipedia
# articles into tidy tibbles. Complements as_wikitable() in wikipedia_tools.R,
# which performs the reverse conversion (data frame -> wikitext markup).

#' Get the Colspan or Rowspan of a Set of Table Cells
#'
#' Internal helper. Reads a span attribute (`"colspan"` or `"rowspan"`) off a
#' set of `<th>`/`<td>` nodes, defaulting to `1` where the attribute is absent.
#'
#' @param cells An `xml_nodeset` of table cell elements.
#' @param attr_name Character. Either `"colspan"` or `"rowspan"`.
#' @return Integer vector, one value per cell.
#' @keywords internal
.cell_span <- function(cells, attr_name) {
  vals <- rvest::html_attr(cells, attr_name)
  vals[is.na(vals)] <- "1"
  as.integer(vals)
}

#' Get Cleaned Text from a Set of Table Cells
#'
#' Internal helper. Extracts rendered text from table cells via
#' [rvest::html_text2()] and, optionally, strips bracketed citation markers
#' (e.g. `"[8]"`, `"[A]"`) that Wikipedia superscripts into cell text.
#'
#' @param cells An `xml_nodeset` of table cell elements.
#' @param strip_citations Logical. If `TRUE` (default), remove citation
#'   markers matching `\\[[0-9]+\\]` or `\\[[A-Za-z]\\]`.
#' @return Character vector, one value per cell.
#' @keywords internal
.cell_text <- function(cells, strip_citations = TRUE) {
  txt <- rvest::html_text2(cells)
  if (isTRUE(strip_citations)) {
    txt <- gsub("\\[[0-9]+\\]|\\[[A-Za-z]\\]", "", txt)
    txt <- trimws(txt)
  }
  txt
}

#' Merge a Two-Row Wikitable Header into One Set of Column Names
#'
#' Internal helper for [get_wikitable()]. Many Wikipedia tables (e.g.
#' discography tables with a "Peak chart positions" super-header spanning
#' several country columns) use a two-row `<th>` header, where cells with
#' `rowspan="2"` apply to both rows and cells with `colspan > 1` are broken
#' out into per-column sub-headers on the second row. This walks both rows
#' in parallel to reconstruct one flat vector of column names.
#'
#' @param row1_cells An `xml_nodeset` of the first header row's cells.
#' @param row2_cells An `xml_nodeset` of the second header row's cells.
#' @param strip_citations Logical, forwarded to [.cell_text()].
#' @return Character vector of column names, one per data column.
#' @keywords internal
.merge_two_header_rows <- function(row1_cells, row2_cells, strip_citations = TRUE) {
  row1_text    <- .cell_text(row1_cells, strip_citations)
  row1_colspan <- .cell_span(row1_cells, "colspan")
  row1_rowspan <- .cell_span(row1_cells, "rowspan")
  row2_text    <- .cell_text(row2_cells, strip_citations)

  names_out <- character(0)
  row2_idx  <- 1
  for (i in seq_along(row1_text)) {
    if (row1_rowspan[i] >= 2) {
      names_out <- c(names_out, rep(row1_text[i], row1_colspan[i]))
    } else {
      cs  <- row1_colspan[i]
      sub <- row2_text[row2_idx:(row2_idx + cs - 1)]
      names_out <- c(names_out, sub)
      row2_idx  <- row2_idx + cs
    }
  }
  names_out
}

#' Expand a Per-Cell Value Vector to a Fixed Column Width
#'
#' Internal helper. Repeats each element of `vals` by its corresponding
#' `colspan`, then pads with `NA` (or truncates) so the result has exactly
#' `total_cols` values. Shared by [.expand_row()] (cell text) and
#' [.expand_row_links()] (cell links).
#'
#' @param vals A vector, one value per cell.
#' @param colspans Integer vector, one colspan per cell, same length as `vals`.
#' @param total_cols Integer. Target row length.
#' @return A vector of length `total_cols`, same type as `vals`.
#' @keywords internal
.expand_vals <- function(vals, colspans, total_cols) {
  out <- unlist(
    mapply(function(v, cs) rep(v, cs), vals, colspans, SIMPLIFY = FALSE, USE.NAMES = FALSE)
  )
  if (length(out) < total_cols) out <- c(out, rep(NA_character_, total_cols - length(out)))
  if (length(out) > total_cols) out <- out[seq_len(total_cols)]
  unname(out)
}

#' Expand One Table Row to a Fixed Column Width
#'
#' Internal helper for [get_wikitable()]. Repeats each cell's text by its
#' `colspan`, then pads with `NA` (or truncates) so every row has exactly
#' `total_cols` values. Does not handle `rowspan` carried over from a
#' previous row into the table body.
#'
#' @param cells An `xml_nodeset` of one row's cells.
#' @param total_cols Integer. Target row length.
#' @param strip_citations Logical, forwarded to [.cell_text()].
#' @return Character vector of length `total_cols`.
#' @keywords internal
.expand_row <- function(cells, total_cols, strip_citations = TRUE) {
  txt      <- .cell_text(cells, strip_citations)
  colspans <- .cell_span(cells, "colspan")
  .expand_vals(txt, colspans, total_cols)
}

#' Extract Row-Header Article Links from One Table Row
#'
#' Internal helper for [get_wikitable()]. For each cell in a row, if the
#' cell is a row-header (`<th>`, as in Wikipedia's common `plainrowheaders`
#' table style -- typically just the first cell, e.g. an album or place
#' name) and contains a link to another Wikipedia article, returns that
#' link's absolute URL; otherwise `NA`. Ordinary `<td>` cells never produce
#' a link, even if they contain one (e.g. a "Label:" link inside an
#' "Album details" cell) -- only the row-header column is a candidate,
#' keeping the default output focused on the one link most likely to be
#' useful (a link to the row's own subject).
#'
#' @param cells An `xml_nodeset` of one row's cells.
#' @param total_cols Integer. Target row length.
#' @param lang Character. Wikipedia language code, used to build an
#'   absolute URL if a link's `href` is relative (e.g. `"/wiki/Foo"`).
#' @return Character vector of length `total_cols`, `NA` where no
#'   row-header link was found.
#' @keywords internal
.expand_row_links <- function(cells, total_cols, lang = "en") {
  tags     <- rvest::html_name(cells)
  colspans <- .cell_span(cells, "colspan")

  raw_links <- vapply(seq_along(cells), function(i) {
    if (tags[i] != "th") {
      return(NA_character_)
    }
    a <- rvest::html_elements(cells[[i]], "a")
    if (length(a) == 0) {
      return(NA_character_)
    }
    hrefs <- rvest::html_attr(a, "href")
    wiki_hrefs <- hrefs[grepl("/wiki/", hrefs, fixed = TRUE)]
    if (length(wiki_hrefs) == 0) NA_character_ else wiki_hrefs[1]
  }, character(1))

  links <- .expand_vals(raw_links, colspans, total_cols)
  is_relative <- !is.na(links) & startsWith(links, "/")
  links[is_relative] <- paste0("https://", lang, ".wikipedia.org", links[is_relative])
  links
}

#' Parse a Wikitable HTML Node into a Tidy Tibble
#'
#' Internal helper for [get_wikitable()]. Splits a `<table>` node's rows into
#' a leading run of header rows (rows composed entirely of `<th>` cells) and
#' the remaining body rows, merges a one- or two-row header into flat column
#' names, and expands each body row's `colspan`s to a consistent width.
#' Single-cell rows in the body (typically legend/footnote rows spanning the
#' whole table) are pulled out into `notes` rather than treated as data. If
#' `extract_links = TRUE`, any row-header column with at least one article
#' link gets an adjacent `<name>_link` column (see [.expand_row_links()]).
#'
#' Header structures deeper than two rows are not specially merged; the raw
#' [rvest::html_table()] output is returned instead, with a message.
#'
#' @param table_node An `xml_node` for one `<table class="wikitable">` element.
#' @param strip_citations Logical, forwarded to [.cell_text()]/[.expand_row()].
#' @param drop_notes Logical. If `TRUE` (default), single-cell body rows are
#'   removed from the data and returned via `notes` instead.
#' @param extract_links Logical. If `TRUE` (default), add a `<name>_link`
#'   column immediately after any row-header column that contains article
#'   links (see [.expand_row_links()]).
#' @param lang Character. Wikipedia language code, forwarded to
#'   [.expand_row_links()] for building absolute URLs.
#' @return A list with elements `data` (tibble) and `notes` (character vector,
#'   possibly empty).
#' @keywords internal
.parse_wikitable_node <- function(table_node, strip_citations = TRUE, drop_notes = TRUE,
                                   extract_links = TRUE, lang = "en") {
  rows <- rvest::html_elements(table_node, "tr")
  if (length(rows) == 0) {
    return(list(data = tibble::tibble(), notes = character(0)))
  }

  row_cells <- lapply(rows, function(r) rvest::html_elements(r, "th, td"))
  row_tags  <- lapply(row_cells, rvest::html_name)
  row_is_header <- vapply(
    row_tags, function(tags) length(tags) > 0 && all(tags == "th"), logical(1)
  )

  header_run <- 0L
  for (is_h in row_is_header) {
    if (is_h) header_run <- header_run + 1L else break
  }
  header_run <- max(header_run, 1L)

  if (header_run > 2L) {
    message(
      "get_wikitable(): header spans ", header_run, " rows; falling back to ",
      "rvest::html_table() without special header merging."
    )
    data <- tibble::as_tibble(rvest::html_table(table_node, header = TRUE, fill = TRUE))
    return(list(data = data, notes = character(0)))
  }

  first_header_cells <- row_cells[[1]]
  total_cols <- sum(.cell_span(first_header_cells, "colspan"))

  col_names <- if (header_run == 1L) {
    rep(.cell_text(first_header_cells, strip_citations),
        .cell_span(first_header_cells, "colspan"))
  } else {
    .merge_two_header_rows(row_cells[[1]], row_cells[[2]], strip_citations)
  }

  body_cells <- row_cells[(header_run + 1L):length(row_cells)]

  parsed_rows <- list()
  parsed_links <- list()
  notes <- character(0)
  for (cells in body_cells) {
    if (isTRUE(drop_notes) && length(cells) == 1L && total_cols > 1L) {
      notes <- c(notes, .cell_text(cells, strip_citations))
      next
    }
    parsed_rows[[length(parsed_rows) + 1L]] <- .expand_row(cells, total_cols, strip_citations)
    if (isTRUE(extract_links)) {
      parsed_links[[length(parsed_links) + 1L]] <- .expand_row_links(cells, total_cols, lang)
    }
  }

  data <- if (length(parsed_rows) == 0) {
    tibble::as_tibble(stats::setNames(
      lapply(col_names, function(x) character(0)), col_names
    ))
  } else {
    body_mat <- do.call(rbind, parsed_rows)
    link_mat <- if (isTRUE(extract_links)) do.call(rbind, parsed_links) else NULL

    final_cols  <- list()
    final_names <- character(0)
    for (j in seq_along(col_names)) {
      final_cols[[length(final_cols) + 1L]] <- body_mat[, j]
      final_names <- c(final_names, col_names[j])

      if (isTRUE(extract_links) && any(!is.na(link_mat[, j]))) {
        final_cols[[length(final_cols) + 1L]] <- link_mat[, j]
        final_names <- c(final_names, paste0(col_names[j], "_link"))
      }
    }
    body_df <- as.data.frame(final_cols, stringsAsFactors = FALSE)
    names(body_df) <- final_names
    tibble::as_tibble(body_df)
  }

  list(data = data, notes = notes)
}

#' Get a Wikitable from a Wikipedia Article
#'
#' Fetches the live, rendered HTML of a Wikipedia article and extracts one of
#' its `class="wikitable"` tables into a tidy tibble. This is the inverse of
#' [as_wikitable()], which converts a data frame *into* wikitext table markup;
#' `get_wikitable()` goes the other direction, pulling a real table *out* of
#' a published article.
#'
#' Many Wikipedia tables (discographies, election results, census figures,
#' etc.) use a two-row header, where a `rowspan="2"` cell like "Title" applies
#' to both header rows and a `colspan` cell like "Peak chart positions" is
#' broken into per-column sub-headers (e.g. "UK", "AUS", "US") on the second
#' row. `get_wikitable()` detects and merges this pattern automatically, so
#' column names come out as the specific sub-header rather than a repeated
#' umbrella label. It also detects and removes single-cell rows that span the
#' full table width -- typically a legend explaining a symbol like a long
#' dash -- keeping their text in the `"notes"` attribute instead of treating
#' them as a data row.
#'
#' When `extract_links = TRUE` (the default), any row-header column --
#' Wikipedia's common `plainrowheaders` style, where the first cell of each
#' body row is a `<th>` naming the row's subject, e.g. an album or place --
#' that links to another article gets an adjacent `<name>_link` column
#' holding that article's absolute URL. Ordinary `<td>` cells are not
#' scanned for links, even if they contain one (e.g. a record label link
#' inside an "Album details" cell); only the row-header link is extracted,
#' since it is the one most likely to identify the row's own subject. Use
#' [link_to_article_name()] to turn a `_link` column's URL into a plain
#' article title, and [clean_column_headers()] to turn the raw header text
#' this function returns (e.g. `"Album details"`, `"Title_link"`) into
#' snake_case variable names (e.g. `"album_details"`, `"title_link"`).
#'
#' @param article_name Character. Article title as it appears in the page's
#'   URL or address bar (spaces or underscores are both accepted).
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @param match Character or `NULL`. A substring to match (case-insensitive)
#'   against each candidate table's `<caption>` text, used to pick the right
#'   table when a page has more than one `wikitable`. If more than one
#'   caption matches, the first is used and a message is printed. Takes
#'   precedence over `index` when supplied.
#' @param index Integer. Which `wikitable` to use (1-based, in document
#'   order), if `match` is `NULL` or matches no caption. Default `1`.
#' @param strip_citations Logical. If `TRUE` (default), citation markers like
#'   `"[8]"` or `"[A]"` are stripped from column names and cell text.
#' @param drop_notes Logical. If `TRUE` (default), single-cell rows spanning
#'   the full table width are excluded from the returned data and preserved
#'   in the `"notes"` attribute instead.
#' @param extract_links Logical. If `TRUE` (default), add a `<name>_link`
#'   column immediately after any row-header column containing article
#'   links, as described in Details.
#'
#' @return A tibble of character columns (Wikipedia tables mix numbers,
#'   dashes, and footnoted text, so no type conversion is attempted). Three
#'   attributes are attached:
#'   \describe{
#'     \item{`caption`}{Character. The `<caption>` text of the table used, or
#'       `NA` if the table had none.}
#'     \item{`url`}{Character. The article URL that was fetched.}
#'     \item{`notes`}{Character vector. Text of any rows excluded by
#'       `drop_notes`; empty if none were found or `drop_notes = FALSE`.}
#'   }
#'
#' @details
#' This function does not handle cells that span multiple *rows* within the
#' table body (only header rows spanning two rows are specially merged); a
#' body cell with `rowspan > 1` will only populate the row it literally
#' appears in, leaving `NA` (from padding) in the rows below it that a
#' rendered browser would visually merge it into. Header structures deeper
#' than two rows fall back to plain [rvest::html_table()] with a message,
#' and links are not extracted in that fallback path.
#'
#' @examples
#' \dontrun{
#' albums <- get_wikitable(
#'   "The Beatles albums discography",
#'   match = "List of studio albums, with selected chart positions and certification"
#' )
#' attr(albums, "caption")
#' attr(albums, "notes")
#'
#' albums <- albums |>
#'   clean_column_headers() |>
#'   dplyr::mutate(title_article = link_to_article_name(title_link)) |>
#'   dplyr::relocate(title_article, .after = title)
#' }
#'
#' @seealso [as_wikitable()], [clean_column_headers()], [link_to_article_name()]
#' @export
get_wikitable <- function(article_name, lang = "en", match = NULL, index = 1,
                           strip_citations = TRUE, drop_notes = TRUE,
                           extract_links = TRUE) {
  stopifnot(is.character(article_name), length(article_name) == 1)

  page_title <- gsub(" ", "_", article_name)
  url <- paste0("https://", lang, ".wikipedia.org/wiki/", utils::URLencode(page_title))

  resp <- httr::GET(url, httr::user_agent("R-wikitools/1.0"))
  if (httr::status_code(resp) >= 400) {
    stop("Failed to fetch page (HTTP ", httr::status_code(resp), "): ", url)
  }

  page <- rvest::read_html(httr::content(resp, as = "text", encoding = "UTF-8"))
  candidates <- rvest::html_elements(page, "table.wikitable")

  if (length(candidates) == 0) {
    stop("No wikitable-class tables found on '", article_name, "'.")
  }

  captions <- vapply(candidates, function(tb) {
    cap <- rvest::html_element(tb, "caption")
    if (is.na(cap)) NA_character_ else rvest::html_text2(cap)
  }, character(1))

  if (!is.null(match)) {
    hits <- which(grepl(toupper(match), toupper(captions), fixed = TRUE))
    if (length(hits) == 0) {
      stop(
        "No table caption on '", article_name, "' matched '", match, "'.\n",
        "Available captions:\n  ",
        paste(captions[!is.na(captions)], collapse = "\n  ")
      )
    }
    if (length(hits) > 1) {
      message(
        "Multiple table captions matched '", match, "'; using the first: \"",
        captions[hits[1]], "\""
      )
    }
    chosen_idx <- hits[1]
  } else {
    if (index > length(candidates)) {
      stop(
        "`index` = ", index, " exceeds the ", length(candidates),
        " wikitable(s) found on '", article_name, "'."
      )
    }
    chosen_idx <- index
  }

  parsed <- .parse_wikitable_node(
    candidates[[chosen_idx]], strip_citations = strip_citations, drop_notes = drop_notes,
    extract_links = extract_links, lang = lang
  )

  out <- parsed$data
  attr(out, "caption") <- captions[chosen_idx]
  attr(out, "url")     <- url
  attr(out, "notes")   <- parsed$notes
  out
}

#' Clean One Header String into a Snake-Case Variable Name
#'
#' Internal helper for [clean_column_headers()]. Strips citation markers,
#' splits the string on whitespace or underscores, lower-cases each
#' resulting word unless it is entirely uppercase letters (an acronym like
#' `"UK"` or `"AUS"`), and rejoins the words with `_`.
#'
#' @param x Character scalar. One header string.
#' @return Character scalar. The cleaned, snake_case name.
#' @keywords internal
.clean_one_header <- function(x) {
  x <- gsub("\\[[0-9]+\\]|\\[[A-Za-z]\\]", "", x)
  words <- strsplit(trimws(x), "[\\s_]+", perl = TRUE)[[1]]
  words <- words[nzchar(words)]
  words <- vapply(words, function(w) {
    if (grepl("^[A-Z]+$", w)) w else tolower(w)
  }, character(1), USE.NAMES = FALSE)
  paste(words, collapse = "_")
}

#' Clean the Column Headers of a Wikitable into Variable Names
#'
#' Converts the raw header text returned by [get_wikitable()] (or any data
#' frame) into snake_case variable names: whitespace is replaced with `_`,
#' citation markers like `"[8]"`/`"[A]"` are discarded, and each word is
#' lower-cased unless it is entirely uppercase (an acronym such as `"UK"` or
#' `"AUS"` is left as-is so it stays recognizable).
#'
#' @param df A data frame or tibble.
#' @return `df` with cleaned column names. Row and column data are
#'   unchanged.
#'
#' @examples
#' \dontrun{
#' albums <- get_wikitable(
#'   "The Beatles albums discography",
#'   match = "List of studio albums, with selected chart positions and certification"
#' )
#' albums <- clean_column_headers(albums)
#' names(albums)[1:5] # "title" "title_link" "album_details" "UK" "AUS"
#' }
#'
#' @seealso [get_wikitable()], [link_to_article_name()]
#' @export
clean_column_headers <- function(df) {
  names(df) <- vapply(names(df), .clean_one_header, character(1), USE.NAMES = FALSE)
  df
}

#' Extract a Wikipedia Article Name from a Link
#'
#' Parses a Wikipedia article URL (or `href`, absolute or relative) and
#' returns the plain article title, with underscores replaced by spaces.
#' Values that don't contain `"/wiki/"` (including `NA`) return `NA`.
#'
#' @param link Character vector of URLs/hrefs, such as the `_link` columns
#'   added by [get_wikitable()].
#' @return Character vector of article titles, same length as `link`.
#'
#' @examples
#' link_to_article_name("https://en.wikipedia.org/wiki/Please_Please_Me")
#' link_to_article_name("/wiki/A_Hard_Day%27s_Night")
#' link_to_article_name(c("https://en.wikipedia.org/wiki/Help!", NA, "not a link"))
#'
#' @seealso [get_wikitable()], [clean_column_headers()]
#' @export
link_to_article_name <- function(link) {
  dplyr::case_when(
    stringr::str_detect(link, "/wiki/") ~ {
      slug <- stringr::str_extract(link, "(?<=/wiki/).*")
      stringr::str_replace_all(slug, "_", " ")
    },
    TRUE ~ NA_character_
  )
}
