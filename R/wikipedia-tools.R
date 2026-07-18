# wikipedia-tools.R
# Compiled utility functions for working with the MediaWiki API and Wikipedia content.
# Sources: get-wikipedia-text-1.R, add-wikipedia-matches.R, import-ice-detention.qmd

#' Fetch Raw Wikitext by Article Name
#'
#' Fetches the raw wikitext of the current revision of a Wikipedia article
#' via the MediaWiki API.
#'
#' @param article_name Character. Wikipedia article title, as it appears in the
#'   page URL (spaces are handled; capitalization matters).
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A character string of wikitext, or `NULL` if the article is not
#'   found or the request fails.
#'
#' @examples
#' \dontrun{
#' wt <- get_wikitext_by_name("Bogot\u00E1")
#' substr(wt, 1, 200)
#' }
#'
#' @seealso [get_wikitext_by_revid()], [get_wikitext_from_url()], [cache_wikitext()]
#' @export
get_wikitext_by_name <- function(article_name, lang = "en") {
  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")

  params <- list(
    action = "query",
    prop = "revisions",
    titles = article_name,
    rvprop = "content",
    rvslots = "main",
    format = "json"
  )

  res <- WikipediR::query(
    url = api_url,
    query = params,
    out_class = "list",
    clean_response = FALSE
  )

  tryCatch({
    page_id <- names(res$query$pages)[1]
    content <- res$query$pages[[page_id]]$revisions[[1]]$slots$main$content
    if (is.null(content)) {
      content <- res$query$pages[[page_id]]$revisions[[1]]$slots$main[["*"]]
    }
    content
  }, error = function(e) {
    NULL
  })
}

#' Fetch Raw Wikitext by Revision ID
#'
#' Fetches raw wikitext for a specific historical revision of a Wikipedia page.
#' The revision ID uniquely identifies the content; the article title is not
#' required by the API and is ignored.
#'
#' @param article_name Character. Ignored. Accepted for interface consistency
#'   but not sent to the API -- the revision ID alone identifies the content.
#' @param revision_id Character or numeric. Wikipedia revision ID, available
#'   from a page's "View history" tab or from the `oldid` query parameter in
#'   a Wikipedia URL.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A character string of wikitext, or `NULL` if the revision is not
#'   found or the request fails.
#'
#' @examples
#' \dontrun{
#' wt <- get_wikitext_by_revid(NA, revision_id = 1171236191)
#' }
#'
#' @seealso [get_wikitext_by_name()], [get_wikitext_from_url()]
#' @export
get_wikitext_by_revid <- function(article_name, revision_id, lang = "en") {
  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")

  params <- list(
    action = "query",
    prop = "revisions",
    revids = as.character(revision_id),
    rvprop = "content",
    rvslots = "main",
    format = "json"
  )

  res <- WikipediR::query(
    url = api_url,
    query = params,
    out_class = "list",
    clean_response = FALSE
  )

  tryCatch({
    page_id <- names(res$query$pages)[1]
    content <- res$query$pages[[page_id]]$revisions[[1]]$slots$main$content
    if (is.null(content)) {
      content <- res$query$pages[[page_id]]$revisions[[1]]$slots$main[["*"]]
    }
    content
  }, error = function(e) {
    NULL
  })
}

#' Fetch Wikitext from a Wikipedia URL
#'
#' Fetches wikitext from a Wikipedia article or historical revision URL.
#' Handles both standard article URLs (`/wiki/Title`) and revision links
#' (`?title=Title&oldid=XXXXXXX`), dispatching to [get_wikitext_by_name()]
#' or [get_wikitext_by_revid()] as appropriate. The language is inferred
#' from the subdomain (e.g., `es.wikipedia.org` as `"es"`).
#'
#' @param url Character. Full Wikipedia URL. Both current-article and
#'   `?oldid=` revision URLs are supported.
#' @return A character string of wikitext, or `NULL` if not retrievable.
#'
#' @examples
#' \dontrun{
#' wt <- get_wikitext_from_url("https://en.wikipedia.org/wiki/La_Paz")
#'
#' # Historical revision
#' wt <- get_wikitext_from_url(
#'   "https://en.wikipedia.org/w/index.php?title=La_Paz&oldid=1171236191"
#' )
#' }
#'
#' @seealso [get_wikitext_by_name()], [get_wikitext_by_revid()]
#' @export
get_wikitext_from_url <- function(url) {
  parsed <- httr::parse_url(url)
  lang <- stringr::str_split(parsed$hostname, "\\.")[[1]][1]

  if (!is.null(parsed$query$oldid)) {
    title <- parsed$query$title
    revid <- parsed$query$oldid
    return(get_wikitext_by_revid(title, revid, lang = lang))
  }

  title <- stringr::str_replace(parsed$path, "wiki/", "")
  get_wikitext_by_name(title, lang = lang)
}

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

#' Get Members of a Wikipedia Category
#'
#' Returns pages and/or subcategories belonging to a Wikipedia category.
#' Handles MediaWiki API pagination automatically, so categories with more
#' than 500 members are fully retrieved.
#'
#' @param category Character. Category name, with or without the `"Category:"`
#'   prefix (it is added automatically if absent).
#' @param type Character. Which members to return: `"page"` (articles only),
#'   `"subcat"` (subcategories only), or `"page|subcat"` (both).
#'   Default is `"page"`.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A tibble with columns:
#'   \describe{
#'     \item{pageid}{Integer. MediaWiki page ID.}
#'     \item{ns}{Integer. MediaWiki namespace (0 = article, 14 = category).}
#'     \item{title}{Character. Page title including namespace prefix.}
#'   }
#'   Returns a zero-row tibble if the category is empty or not found.
#'
#' @examples
#' \dontrun{
#' get_wp_category_members("Capitals of South America")
#' get_wp_category_members("Capitals of South America", type = "subcat")
#' }
#'
#' @seealso [get_wp_subcategories()], [get_wp_category_pages()], [get_page_info_batch()]
#' @export
get_wp_category_members <- function(category, type = "page", lang = "en") {
  if (!grepl("^Category:", category)) {
    category <- paste0("Category:", category)
  }

  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")
  all_members <- list()
  cmcontinue <- NULL

  repeat {
    params <- list(
      action = "query",
      list = "categorymembers",
      cmtitle = category,
      cmtype = type,
      cmlimit = "500",
      format = "json"
    )

    if (!is.null(cmcontinue)) {
      params$cmcontinue <- cmcontinue
    }

    resp <- httr::GET(
      api_url,
      query = params,
      httr::user_agent("R-wikipedia-tools/1.0")
    )
    json <- jsonlite::fromJSON(
      httr::content(resp, "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )

    members <- json$query$categorymembers
    if (length(members) > 0) {
      all_members <- c(all_members, members)
    }

    cmcontinue <- json$`continue`$cmcontinue
    if (is.null(cmcontinue)) {
      break
    }
  }

  if (length(all_members) == 0) {
    return(tibble::tibble(pageid = integer(), ns = integer(), title = character()))
  }

  dplyr::bind_rows(lapply(all_members, function(member) {
    tibble::tibble(pageid = member$pageid, ns = member$ns, title = member$title)
  }))
}

#' Get Subcategories of a Wikipedia Category
#'
#' Convenience wrapper around [get_wp_category_members()] that returns
#' only subcategories (`type = "subcat"`).
#'
#' @param category Character. Category name, with or without `"Category:"` prefix.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A tibble with columns `pageid`, `ns`, and `title`.
#'
#' @examples
#' \dontrun{
#' get_wp_subcategories("South American countries")
#' }
#'
#' @seealso [get_wp_category_members()], [get_wp_category_pages()]
#' @export
get_wp_subcategories <- function(category, lang = "en") {
  get_wp_category_members(category, type = "subcat", lang = lang)
}

#' Get Pages in a Wikipedia Category
#'
#' Convenience wrapper around [get_wp_category_members()] that returns
#' only article pages (`type = "page"`), excluding subcategories.
#'
#' @param category Character. Category name, with or without `"Category:"` prefix.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A tibble with columns `pageid`, `ns`, and `title`.
#'
#' @examples
#' \dontrun{
#' get_wp_category_pages("Capitals of South America")
#' }
#'
#' @seealso [get_wp_category_members()], [get_wp_subcategories()]
#' @export
get_wp_category_pages <- function(category, lang = "en") {
  get_wp_category_members(category, type = "page", lang = lang)
}

#' Fetch Page Metadata in Batches
#'
#' Fetches basic metadata for a vector of Wikipedia page titles, batching
#' requests at 50 titles per API call. Useful for linking Wikipedia articles
#' to their Wikidata items or checking page sizes in bulk.
#'
#' @param titles Character vector. Wikipedia page titles.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A tibble with one row per page and columns:
#'   \describe{
#'     \item{title}{Character. Normalized page title as returned by the API.}
#'     \item{pageid}{Integer. MediaWiki page ID, or `NA` for missing pages.}
#'     \item{page_length}{Integer. Page size in bytes, or `NA` for missing pages.}
#'     \item{wikidata_qid}{Character. Linked Wikidata item QID (e.g., `"Q2887"`),
#'       or `NA` if none is set.}
#'   }
#'
#' @examples
#' \dontrun{
#' titles <- c("La Paz", "Santa Cruz de la Sierra", "Cochabamba")
#' get_page_info_batch(titles, lang = "es")
#' }
#'
#' @seealso [get_wp_category_members()]
#' @export
get_page_info_batch <- function(titles, lang = "en") {
  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")
  results <- list()
  batches <- split(titles, ceiling(seq_along(titles) / 50))

  for (batch in batches) {
    params <- list(
      action = "query",
      prop = "pageprops|info",
      titles = paste(batch, collapse = "|"),
      format = "json",
      ppprop = "wikibase_item"
    )

    resp <- httr::GET(
      api_url,
      query = params,
      httr::user_agent("R-wikipedia-tools/1.0")
    )

    json <- jsonlite::fromJSON(
      httr::content(resp, "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )

    pages <- json$query$pages
    for (p in pages) {
      title <- if (is.null(p$title)) NA_character_ else p$title
      pageid <- if (is.null(p$pageid)) NA_integer_ else p$pageid
      page_length <- if (is.null(p$length)) NA_integer_ else p$length
      wikidata_qid <- if (is.null(p$pageprops$wikibase_item)) {
        NA_character_
      } else {
        p$pageprops$wikibase_item
      }

      results <- c(results, list(tibble::tibble(
        title = title,
        pageid = pageid,
        page_length = page_length,
        wikidata_qid = wikidata_qid
      )))
    }

    Sys.sleep(0.2)
  }

  dplyr::bind_rows(results)
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

#' Cache Wikitext Locally
#'
#' Fetches and stores article wikitext as a plain-text file, returning the
#' cached copy on subsequent calls without an API request. Useful when
#' processing many articles or re-running analyses repeatedly.
#'
#' File names are derived from the article title with the characters
#' `/ : * ? " < > |` replaced by underscores.
#'
#' @param title Character. Wikipedia page title.
#' @param cache_dir Character. Path to the directory where cached `.txt` files
#'   are stored. The directory must already exist.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A character string of wikitext, or `NULL` if the page is not found.
#'   When a cached file exists, it is read and returned without an API call.
#'
#' @examples
#' \dontrun{
#' dir.create("wikitext_cache", showWarnings = FALSE)
#' wt <- cache_wikitext("Sucre", cache_dir = "wikitext_cache", lang = "es")
#' # Second call reads from disk, no API request made
#' wt <- cache_wikitext("Sucre", cache_dir = "wikitext_cache", lang = "es")
#' }
#'
#' @seealso [get_wikitext_by_name()], [extract_clean_fragments()], [extract_infobox()]
#' @export
cache_wikitext <- function(title, cache_dir, lang = "en") {
  safe_name <- gsub("[/:*?\"<>|]", "_", title)
  cache_path <- file.path(cache_dir, paste0(safe_name, ".txt"))

  if (file.exists(cache_path)) {
    return(paste(readLines(cache_path, warn = FALSE), collapse = "\n"))
  }

  wikitext <- get_wikitext_by_name(title, lang = lang)
  if (!is.null(wikitext)) {
    writeLines(wikitext, cache_path)
  }

  wikitext
}
