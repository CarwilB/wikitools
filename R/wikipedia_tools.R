# wikipedia_tools.R
# Wikitext parsing and analysis utilities (no internet required).
# These functions process raw wikitext to extract infoboxes, clean markup,
# count citations/references, and analyze content structure.
#
# For Wikipedia API functions (fetching wikitext, category operations), see get-wikipedia-text.R

#' Extract Clean Text Fragments from Wikitext
#'
#' Strips wikitext markup and splits the result into sentence-like fragments.
#' Removed markup includes: `<ref>` tags, templates (`\{\{ \}\}`), file/image
#' links, section headers, and bold/italic formatting. Wikilinks are either
#' kept (display text only) or removed entirely depending on `keep_link_text`.
#' Fragments shorter than five words are discarded.
#'
#' @param wikitext Character. Raw wikitext string.
#' @param keep_link_text Logical. If `TRUE`, retains the display text of
#'   `[[Target|Display]]` wikilinks. If `FALSE` (default), wikilinks are
#'   removed entirely.
#' @return A character vector of unique cleaned text fragments, each containing
#'   at least five words. Fragments are split on `.`, `!`, `?`, and newlines.
#'
#' @examples
#' wt <- "La Paz is the [[seat of government]] of [[Bolivia]].
#'   It was founded in [[1548]].<ref>Smith 2000</ref>"
#' extract_clean_fragments(wt)
#' extract_clean_fragments(wt, keep_link_text = TRUE)
#'
#' @seealso [get_wikitext_by_name()], [cache_wikitext()]
#' @export
extract_clean_fragments <- function(wikitext, keep_link_text = FALSE) {
  clean_text <- stringr::str_replace_all(wikitext, "(?s)<ref.*?>.*?</ref>", "")
  clean_text <- stringr::str_replace_all(clean_text, "<ref.*?/>", "")
  clean_text <- gsub("\\{\\{(?:[^{}]|(?R))*\\}\\}", "", clean_text, perl = TRUE)
  clean_text <- stringr::str_replace_all(clean_text, "(?i)\\[\\[(File|Image):.*?\\]\\]", "")

  if (keep_link_text) {
    clean_text <- stringr::str_replace_all(
      clean_text,
      "\\[\\[(?:[^|\\]]*\\|)?([^\\]]+)\\]\\]",
      "\\1"
    )
  } else {
    clean_text <- stringr::str_replace_all(clean_text, "\\[\\[.*?\\]\\]", "")
  }

  clean_text <- stringr::str_replace_all(clean_text, "==+.*?==+", "")
  clean_text <- stringr::str_replace_all(clean_text, "''+", "")

  fragments <- unlist(stringr::str_split(clean_text, "[\\.\\!\\?\\n\\r]"))
  fragments <- stringr::str_trim(fragments)
  fragments <- stringr::str_replace_all(fragments, "\\s+", " ")
  final_list <- fragments[stringr::str_count(fragments, "\\w+") >= 5]
  unique(final_list)
}

#' Format a Data Frame as a MediaWiki Wikitable
#'
#' Converts a data frame to a MediaWiki wikitable string, ready to paste into
#' a Wikipedia article. Columns become headers; each row becomes a table row.
#' `NA` values are rendered as empty cells.
#'
#' @param df A data frame.
#' @param caption Character. Optional table caption displayed above the table.
#' @param class Character. CSS class string applied to the table tag.
#'   Default `"wikitable sortable"` produces a bordered, user-sortable table.
#' @param column_names Character vector. Optional display names for columns.
#'   Must have the same length as `ncol(df)` if supplied. Defaults to the
#'   data frame's column names.
#' @return A single character string of wikitable markup.
#'
#' @examples
#' df <- data.frame(City = c("La Paz", "Santa Cruz"), Pop = c(835361, 1453549))
#' cat(as_wikitable(df, caption = "Bolivian cities"))
#'
#' @seealso [get_wp_category_members()]
#' @export
as_wikitable <- function(df, caption = NULL, class = "wikitable sortable",
                          column_names = NULL) {
  out <- c()
  out <- c(out, paste0('{| class="', class, '"'))
  if (!is.null(caption)) {
    out <- c(out, paste0("|+ ", caption))
  }

  if (is.null(column_names)) {
    column_names <- names(df)
  }
  out <- c(out, paste0("! ", paste(column_names, collapse = " !! ")))

  formatted_rows <- apply(df, 1, function(row) {
    row_clean <- gsub("\\|", "|", as.character(row))
    row_clean[is.na(row_clean)] <- ""
    paste0("| ", paste(row_clean, collapse = " || "))
  })

  out <- c(out, paste0("|-\n", formatted_rows))
  out <- c(out, "|}")
  paste(out, collapse = "\n")
}

#' Extract the First Infobox from Wikitext
#'
#' Parses the first `\{\{Infobox ...\}\}` template from raw wikitext into a named
#' list of field-value pairs. Uses brace-depth matching to correctly handle
#' nested templates within field values. Only the first infobox is extracted
#' if the article contains multiple. Field values are returned as-is (raw
#' wikitext); use [clean_infobox_value()] to strip markup.
#'
#' @param wikitext Character. Raw wikitext string, as returned by
#'   [get_wikitext_by_name()] or [cache_wikitext()].
#' @return A named list where each element is a raw wikitext field value, or
#'   `NULL` if no infobox is found or `wikitext` is `NULL`.
#'
#' @examples
#' \dontrun{
#' wt <- get_wikitext_by_name("La Paz")
#' box <- extract_infobox(wt)
#' clean_infobox_value(box[["population_total"]])
#' }
#'
#' @seealso [clean_infobox_value()], [get_wikitext_by_name()]
#' @export
extract_infobox <- function(wikitext) {
  if (is.null(wikitext)) {
    return(NULL)
  }

  infobox_start <- regexpr("\\{\\{\\s*[Ii]nfobox", wikitext)
  if (infobox_start == -1) {
    return(NULL)
  }

  txt <- substring(wikitext, infobox_start)
  depth <- 0
  end_pos <- NA
  i <- 1

  while (i <= nchar(txt)) {
    ch <- substr(txt, i, i)

    if (ch == "{" && i < nchar(txt) && substr(txt, i + 1, i + 1) == "{") {
      depth <- depth + 1
      i <- i + 2
      next
    }

    if (ch == "}" && i < nchar(txt) && substr(txt, i + 1, i + 1) == "}") {
      depth <- depth - 1
      if (depth == 0) {
        end_pos <- i + 1
        break
      }
      i <- i + 2
      next
    }

    i <- i + 1
  }

  if (is.na(end_pos)) {
    return(NULL)
  }

  infobox_text <- substr(txt, 1, end_pos)
  inner <- sub("^\\{\\{\\s*[Ii]nfobox[^\\n|]*", "", infobox_text)
  inner <- sub("\\}\\}$", "", inner)

  params <- split_on_top_level_pipes(inner)

  result <- list()
  for (param in params) {
    param <- stringr::str_trim(param)
    if (param == "" || !grepl("=", param)) {
      next
    }

    eq_pos <- regexpr("=", param)
    key <- stringr::str_trim(substr(param, 1, eq_pos - 1))
    val <- stringr::str_trim(substr(param, eq_pos + 1, nchar(param)))

    if (nchar(key) > 0) {
      result[[key]] <- val
    }
  }

  result
}

#' Split Text on Top-Level Pipe Characters
#'
#' Splits a string on `|` characters that appear at the top nesting level
#' (i.e., outside `\{\{ \}\}` template and `[[ ]]` link blocks). Used internally
#' to parse infobox fields without splitting on pipes inside nested templates.
#'
#' @param text Character string to split.
#' @return A character vector of segments.
#' @keywords internal
split_on_top_level_pipes <- function(text) {
  parts <- character()
  depth <- 0
  current <- ""
  i <- 1

  while (i <= nchar(text)) {
    ch <- substr(text, i, i)

    if (ch == "{" && i < nchar(text) && substr(text, i + 1, i + 1) == "{") {
      depth <- depth + 1
      current <- paste0(current, "{{")
      i <- i + 2
      next
    }

    if (ch == "}" && i < nchar(text) && substr(text, i + 1, i + 1) == "}") {
      depth <- depth - 1
      current <- paste0(current, "}}")
      i <- i + 2
      next
    }

    if (ch == "[" && i < nchar(text) && substr(text, i + 1, i + 1) == "[") {
      depth <- depth + 1
      current <- paste0(current, "[[")
      i <- i + 2
      next
    }

    if (ch == "]" && i < nchar(text) && substr(text, i + 1, i + 1) == "]") {
      depth <- depth - 1
      current <- paste0(current, "]]")
      i <- i + 2
      next
    }

    if (ch == "|" && depth == 0) {
      parts <- c(parts, current)
      current <- ""
    } else {
      current <- paste0(current, ch)
    }
    i <- i + 1
  }

  if (nchar(current) > 0) {
    parts <- c(parts, current)
  }

  parts
}

#' Clean a Single Infobox Field Value
#'
#' Strips wikitext and HTML markup from a raw infobox field value, returning
#' readable plain text. Handles: `<ref>` tags, arbitrary HTML tags, wikilinks
#' (keeping display text), `\{\{flag\}\}` / `\{\{flagicon\}\}` / `\{\{flagcountry\}\}`
#' templates (keeping the country name), `\{\{convert\}\}` templates (keeping
#' value and unit), `\{\{nowrap\}\}`, remaining `\{\{ \}\}` templates, and bare
#' external links.
#'
#' @param val Character. Raw infobox field value, typically an element of the
#'   list returned by [extract_infobox()].
#' @return A cleaned character string, or `NA_character_` if the input is
#'   `NULL`, `NA`, or resolves to an empty string after cleaning.
#'
#' @examples
#' clean_infobox_value("[[Buenos Aires]]")        # "Buenos Aires"
#' clean_infobox_value("{{flag|Bolivia}}")        # "Bolivia"
#' clean_infobox_value("3,000<ref>Census</ref>")  # "3,000"
#' clean_infobox_value(NA)                        # NA_character_
#'
#' @seealso [extract_infobox()]
#' @export
clean_infobox_value <- function(val) {
  if (is.null(val) || is.na(val)) {
    return(NA_character_)
  }

  val <- stringr::str_replace_all(val, "(?s)<ref[^>]*>.*?</ref>", "")
  val <- stringr::str_replace_all(val, "<ref[^/]*/\\s*>", "")
  val <- stringr::str_replace_all(val, "<[^>]+>", "")
  val <- stringr::str_replace_all(val, "\\[\\[(?:[^|\\]]*\\|)?([^\\]]+)\\]\\]", "\\1")
  val <- stringr::str_replace_all(val, "\\{\\{(?:flag|flagicon|flagcountry)\\|([^{}|]+)(?:\\|[^{}]*)??\\}\\}", "\\1")
  val <- stringr::str_replace_all(val, "\\{\\{convert\\|([^{}|]+)\\|([^{}|]+)(?:\\|[^{}]*)?\\}\\}", "\\1 \\2")
  val <- stringr::str_replace_all(val, "\\{\\{nowrap\\|([^{}]+)\\}\\}", "\\1")
  val <- gsub("\\{\\{(?:[^{}]|(?R))*\\}\\}", "", val, perl = TRUE)
  val <- stringr::str_replace_all(val, "\\[https?://\\S+\\s+([^\\]]+)\\]", "\\1")
  val <- stringr::str_replace_all(val, "\\[https?://\\S+\\]", "")
  val <- stringr::str_trim(stringr::str_squish(val))

  if (nchar(val) == 0) {
    NA_character_
  } else {
    val
  }
}

#' Count Citation Templates in Wikitext
#'
#' Counts occurrences of `\{\{cite ...\}\}` and `\{\{Citation ...\}\}` templates.
#' Note that bare `<ref>` tags without a citation template (e.g., named
#' references or bare URLs) are not counted here; see [count_refs()] for those.
#'
#' @param wikitext Character. Raw wikitext string.
#' @return Integer. Number of citation templates found. Returns `0L` if
#'   `wikitext` is `NULL`.
#'
#' @examples
#' wt <- "Text.\\{\\{cite book|author=Smith|year=2000\\}\\}
#'   More text.\\{\\{Citation|author=Jones\\}\\}<ref name='x'/>"
#' count_citations(wt)  # 2
#' count_refs(wt)       # 2
#'
#' @seealso [count_refs()]
#' @export
count_citations <- function(wikitext) {
  if (is.null(wikitext)) {
    return(0L)
  }

  cite_pattern <- "\\{\\{\\s*[Cc]it(e|ation)\\s"
  length(stringr::str_extract_all(wikitext, cite_pattern)[[1]])
}

#' Count Reference Tags in Wikitext
#'
#' Counts `<ref>` opening tags in wikitext, including self-closing tags
#' (`<ref name="x" />`). Counts distinct inline references, not closing
#' `</ref>` tags. For citation template counts, see [count_citations()].
#'
#' @param wikitext Character. Raw wikitext string.
#' @return Integer. Number of `<ref>` tags found. Returns `0L` if `wikitext`
#'   is `NULL`.
#'
#' @examples
#' wt <- "<ref>Smith 2000</ref> text <ref name='jones'/> more"
#' count_refs(wt)  # 2
#'
#' @seealso [count_citations()]
#' @export
count_refs <- function(wikitext) {
  if (is.null(wikitext)) {
    return(0L)
  }

  ref_pattern <- "<ref[\\s>]"
  self_closing <- "<ref\\s[^>]*/>"

  length(stringr::str_extract_all(wikitext, ref_pattern)[[1]]) +
    length(stringr::str_extract_all(wikitext, self_closing)[[1]])
}

#' Extract Census Years from Wikitext
#'
#' Scans wikitext for common census year patterns and returns any four-digit
#' years found. Recognized patterns include (case-insensitive):
#' - `YYYY census` and `YYYY <word> census`
#' - `census of YYYY`
#' - `censo de YYYY` (Spanish)
#' - `CPV YYYY` (used in Bolivian census references)
#' - `census_year = YYYY` and `population_as_of = YYYY` (infobox fields)
#'
#' @param wikitext Character. Raw wikitext string.
#' @return A sorted character vector of unique four-digit year strings.
#'   Returns `character(0)` if `wikitext` is `NULL` or no years are found.
#'
#' @examples
#' wt <- "According to the 2001 census, and the 2012 census..."
#' extract_census_years(wt)  # c("2001", "2012")
#'
#' wt2 <- "| population_as_of = 2024"
#' extract_census_years(wt2)  # "2024"
#'
#' @seealso [extract_infobox()], [count_citations()]
#' @export
extract_census_years <- function(wikitext) {
  if (is.null(wikitext)) {
    return(character(0))
  }

  patterns <- c(
    "(?i)\\b(\\d{4})\\s+census\\b",
    "(?i)\\b(\\d{4})\\s+\\w+\\s+census\\b",
    "(?i)\\bcensus\\s+(?:of\\s+)?(\\d{4})\\b",
    "(?i)\\bcenso\\s+(?:de\\s+)?(\\d{4})\\b",
    "(?i)\\bCPV\\s+(\\d{4})\\b",
    "(?i)\\bcensus_year\\s*=\\s*(\\d{4})",
    "(?i)\\bpopulation_as_of\\s*=\\s*(\\d{4})"
  )

  years <- character(0)
  for (pat in patterns) {
    matches <- stringr::str_match_all(wikitext, pat)[[1]]
    if (nrow(matches) > 0) {
      years <- c(years, matches[, 2])
    }
  }

  sort(unique(years[!is.na(years) & nchar(years) == 4]))
}

#' Convert Wikitext to Plain Text via Pandoc
#'
#' Converts a raw wikitext string to clean plain text using Pandoc's MediaWiki
#' reader. Pandoc must be installed on the system; use
#' `rmarkdown::pandoc_available()` to check. Unlike [extract_clean_fragments()],
#' this preserves the full document structure (headers, lists, tables) as
#' plain prose rather than splitting into sentence fragments.
#'
#' @param wikitext Character. Raw wikitext string, as returned by
#'   [get_wikitext_by_name()] or [cache_wikitext()].
#' @return A single character string of plain text.
#'
#' @examples
#' \dontrun{
#' wt <- get_wikitext_by_name("Bolivia")
#' plain <- wikitext_to_plain(wt)
#' cat(substr(plain, 1, 500))
#' }
#'
#' @seealso [get_plain_text()], [extract_clean_fragments()]
#' @export
wikitext_to_plain <- function(wikitext) {
  if (!rmarkdown::pandoc_available()) {
    stop("Pandoc is not available. Install Pandoc or check your rmarkdown setup.")
  }

  input_file  <- tempfile(fileext = ".wiki")
  output_file <- tempfile(fileext = ".txt")
  on.exit(unlink(c(input_file, output_file)))

  writeLines(wikitext, input_file, useBytes = TRUE)

  tryCatch(
    rmarkdown::pandoc_convert(
      input  = input_file,
      from   = "mediawiki",
      to     = "plain",
      output = output_file
    ),
    error = function(e) stop("Pandoc conversion failed: ", e$message)
  )

  if (!file.exists(output_file)) {
    stop("Pandoc ran but did not produce an output file.")
  }

  paste(readLines(output_file, warn = FALSE), collapse = "\n")
}
