# wikipedia-tools.R
# Compiled utility functions for working with the MediaWiki API and Wikipedia content.
# Sources: get-wikipedia-text-1.R, add-wikipedia-matches.R, import-ice-detention.qmd

#' Fetch Raw Wikitext by Article Name
#'
#' @title Fetch Raw Wikitext by Article Name
#' @description Fetches the raw wikitext of a current Wikipedia article via the
#'   MediaWiki API.
#' @param article_name Character. Wikipedia article title.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A character string containing article wikitext, or `NULL` if unavailable.
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
#' @title Fetch Raw Wikitext by Revision ID
#' @description Fetches raw wikitext for a specific historical revision of a
#'   Wikipedia page.
#' @param article_name Character. Article title (kept for API compatibility).
#' @param revision_id Character or numeric. Specific Wikipedia revision ID.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A character string containing revision wikitext, or `NULL` if unavailable.
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
#' @title Fetch Wikitext from a Wikipedia URL
#' @description Parses a Wikipedia URL (including `?oldid=` revision links) and
#'   dispatches to either `get_wikitext_by_name()` or `get_wikitext_by_revid()`.
#' @param url Character. Full Wikipedia URL.
#' @return A character string containing wikitext, or `NULL` when not retrievable.
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
#' @title Extract Clean Text Fragments from Wikitext
#' @description Strips common wikitext markup and splits the result into
#'   sentence-like fragments with at least five words.
#' @param wikitext Character. Raw wikitext string.
#' @param keep_link_text Logical. If `TRUE`, keeps display text from wikilinks;
#'   if `FALSE`, removes wikilinks entirely.
#' @return A character vector of unique cleaned fragments.
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
#' @title Format a Data Frame as a MediaWiki Wikitable
#' @description Formats a data frame as a MediaWiki wikitable string ready to
#'   paste into a Wikipedia page.
#' @param df A data frame.
#' @param caption Optional character table caption.
#' @param class Character. CSS classes for the table.
#' @param column_names Optional character vector of display column names.
#' @return A single character string containing wikitable markup.
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
#' @title Get Members of a Wikipedia Category
#' @description Returns pages and/or subcategories from a Wikipedia category,
#'   handling MediaWiki pagination.
#' @param category Character. Category name, with or without `"Category:"` prefix.
#' @param type Character. One of `"page"`, `"subcat"`, or `"page|subcat"`.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A tibble with columns `pageid`, `ns`, and `title`.
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

#' Get Subcategories from a Category
#'
#' @title Get Subcategories from a Category
#' @description Convenience wrapper around `get_category_members()` for
#'   subcategories only.
#' @param category Character. Category name.
#' @param lang Character. Wikipedia language code.
#' @return A tibble with category subcategory members.
#' @export
get_wp_subcategories <- function(category, lang = "en") {
  get_category_members(category, type = "subcat", lang = lang)
}

#' Get Pages from a Category
#'
#' @title Get Pages from a Category
#' @description Convenience wrapper around `get_category_members()` for pages
#'   only (non-recursive).
#' @param category Character. Category name.
#' @param lang Character. Wikipedia language code.
#' @return A tibble with page members.
#' @export
get_wp_category_pages <- function(category, lang = "en") {
  get_category_members(category, type = "page", lang = lang)
}

#' Fetch Page Metadata in Batches
#'
#' @title Fetch Page Metadata in Batches
#' @description Fetches basic metadata (title, page ID, length, and Wikidata QID)
#'   for Wikipedia titles in API batches of up to 50.
#' @param titles Character vector of page titles.
#' @param lang Character. Wikipedia language code.
#' @return A tibble with columns `title`, `pageid`, `page_length`, and
#'   `wikidata_qid`.
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

#' Extract the First Infobox Template
#'
#' @title Extract the First Infobox Template
#' @description Parses the first infobox template from wikitext into a named list
#'   of key-value fields using brace-depth matching.
#' @param wikitext Character. Raw article wikitext.
#' @return A named list of infobox fields, or `NULL` when no infobox is found.
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
#' @title Split Text on Top-Level Pipe Characters
#' @description Splits a string on `|` characters that appear at top nesting
#'   level (outside `{{ }}` and `[[ ]]` blocks).
#' @param text Character string to split.
#' @return A character vector of split segments.
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
#' @title Clean a Single Infobox Field Value
#' @description Removes common wikitext and HTML markup from an infobox value,
#'   returning a readable plain-text string.
#' @param val Character. Raw infobox field value.
#' @return A cleaned character string, or `NA_character_` when empty/unavailable.
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
#' @title Count Citation Templates in Wikitext
#' @description Counts occurrences of `{{cite ...}}` and `{{Citation ...}}`
#'   templates in wikitext.
#' @param wikitext Character. Raw wikitext string.
#' @return Integer count of citation templates.
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
#' @title Count Reference Tags in Wikitext
#' @description Counts `<ref>` tags in wikitext, including self-closing
#'   reference tags.
#' @param wikitext Character. Raw wikitext string.
#' @return Integer count of reference tags.
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
#' @title Extract Census Years from Wikitext
#' @description Extracts four-digit years from common census patterns in
#'   wikitext (e.g., `YYYY census`, `census of YYYY`, `CPV YYYY`).
#' @param wikitext Character. Raw wikitext string.
#' @return A sorted character vector of unique four-digit years.
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
#' @title Cache Wikitext Locally
#' @description Saves article wikitext to a local file and returns cached content
#'   on subsequent calls when available.
#' @param title Character. Wikipedia page title.
#' @param cache_dir Character. Directory where cached files are stored.
#' @param lang Character. Wikipedia language code.
#' @return A character string of wikitext, or `NULL` when the page is unavailable.
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
