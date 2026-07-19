# get-wikipedia-text.R
# Wikipedia text retrieval and category functions via MediaWiki API
# Functions: get_wikitext_by_name, get_wikitext_by_revid, get_wikitext_from_url,
#            get_wp_category_members, get_wp_subcategories, get_wp_category_pages,
#            get_page_info_batch, cache_wikitext

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

  resp <- httr::GET(api_url, query = params, httr::user_agent("R-wikitools/1.0"))

  tryCatch({
    res <- jsonlite::fromJSON(
      httr::content(resp, "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )
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

  resp <- httr::GET(api_url, query = params, httr::user_agent("R-wikitools/1.0"))

  tryCatch({
    res <- jsonlite::fromJSON(
      httr::content(resp, "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )
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

#' Fetch Plain Text of a Wikipedia Article
#'
#' Fetches the rendered HTML of a Wikipedia article or historical revision via
#' the MediaWiki parse API, then strips all HTML tags to return clean plain
#' text. Unlike [get_wikitext_by_name()], this returns human-readable prose
#' rather than raw markup.
#'
#' @param title Character. Wikipedia article title. Supply either `title` or
#'   `revision_id`, not both.
#' @param revision_id Numeric or character. Wikipedia revision ID. Supply
#'   either `title` or `revision_id`, not both.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A character string of plain text, or `NULL` if the article cannot
#'   be retrieved or parsed.
#'
#' @examples
#' \dontrun{
#' text <- get_plain_text("Bolivia")
#' cat(substr(text, 1, 500))
#'
#' # Historical revision
#' text <- get_plain_text(revision_id = 1171236191)
#' }
#'
#' @seealso [get_wikitext_by_name()], [wikitext_to_plain()]
#' @export
get_plain_text <- function(title = NULL, revision_id = NULL, lang = "en") {
  if (is.null(title) && is.null(revision_id)) {
    stop("You must provide either a title or a revision_id.")
  }

  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")

  params <- list(action = "parse", prop = "text", format = "json")

  if (!is.null(revision_id)) {
    params$oldid <- revision_id
  } else {
    params$page <- title
  }

  resp <- httr::GET(api_url, query = params, httr::user_agent("R-wikitools/1.0"))

  if (httr::status_code(resp) != 200L) {
    stop("Failed to connect to Wikipedia API.")
  }

  tryCatch({
    data <- httr::content(resp, "parsed")
    html_string <- data$parse$text[[1]]
    rvest::read_html(html_string) |> rvest::html_text2()
  }, error = function(e) {
    warning("Could not parse content. The revision ID may be invalid or restricted.")
    NULL
  })
}
