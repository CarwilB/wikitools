#' Search Wikipedia and Return All Hits for One Query
#'
#' Internal helper called row-wise by [find_wikipedia_matches()].
#' Uses the MediaWiki search API via `httr` and `jsonlite`.
#'
#' @param query Character. Search string.
#' @param lang Character. Wikipedia language code.
#' @param limit Integer. Maximum number of search results to request.
#' @return A tibble with columns `title`, `url`, and `snippet`, one row per
#'   search hit (zero rows when the query is blank, the search returns no
#'   results, or a request error occurs).
#' @keywords internal
search_wikipedia_all <- function(query, lang = "en", limit = 6) {
  empty <- tibble::tibble(
    title = character(),
    url = character(),
    snippet = character()
  )

  if (is.na(query) || !nzchar(trimws(query))) {
    return(empty)
  }

  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")
  resp <- tryCatch(
    httr::GET(api_url, query = list(
      action   = "query",
      list     = "search",
      srsearch = query,
      srlimit  = limit,
      format   = "json"
    )),
    error = function(e) NULL
  )

  if (is.null(resp) || httr::status_code(resp) >= 400) {
    return(empty)
  }

  json <- jsonlite::fromJSON(
    httr::content(resp, as = "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )
  hits <- json$query$search

  if (is.null(hits) || length(hits) == 0) {
    return(empty)
  }

  titles <- vapply(hits, function(h) {
    if (!is.null(h$title)) as.character(h$title) else NA_character_
  }, character(1))
  snippets <- vapply(hits, function(h) {
    if (!is.null(h$snippet)) as.character(h$snippet) else NA_character_
  }, character(1))

  tibble::tibble(
    title = titles,
    url = paste0(
      "https://", lang, ".wikipedia.org/wiki/",
      utils::URLencode(gsub(" ", "_", titles), reserved = TRUE)
    ),
    snippet = snippets
  )
}

#' Find the Top Wikipedia Search Candidates for Each String
#'
#' Searches Wikipedia for each string and returns the top `n` search hits
#' per string, rather than only the single top result as in
#' [add_wikipedia_matches()]. Useful when the correct article may not be the
#' first hit — for example, disambiguated titles like
#' `"Revolver (Beatles album)"` that rank below a more general page.
#'
#' @param x Character vector of search strings, or a data frame containing
#'   `name_col`.
#' @param n Integer. Number of search hits to return per string
#'   (default `6`).
#' @param name_col Character. When `x` is a data frame, the name of the
#'   column containing search strings. Ignored when `x` is a character
#'   vector.
#' @param lang Character. Wikipedia language code (default `"en"`). Unlike
#'   [add_wikipedia_matches()], only a single language is searched per call.
#' @param delay Numeric. Seconds to pause between requests (default `0.5`).
#'   Set to `0` in tests or batch jobs where rate-limiting is handled
#'   elsewhere.
#' @return A tibble with one row per search hit and columns:
#'   \describe{
#'     \item{query}{Character. The search string.}
#'     \item{rank}{Integer. Position of the hit in the search results
#'       (1 = top).}
#'     \item{match}{Logical. `TRUE` if this hit's title matches the query
#'       exactly (case- and whitespace-insensitive).}
#'     \item{title}{Character. Article title of the hit.}
#'     \item{url}{Character. Full Wikipedia URL of the hit.}
#'     \item{snippet}{Character. HTML snippet from the search result.}
#'   }
#'   Strings with no hits (or blank/`NA` strings) appear once with
#'   `rank = NA_integer_` and `NA` in the hit columns, so every input string
#'   is represented in the output.
#'
#' @examples
#' \dontrun{
#' find_wikipedia_matches(c("Revolver", "Let It Be"))
#' find_wikipedia_matches(c("Revolver", "Let It Be"), n = 3)
#'
#' albums <- tibble::tibble(title = c("Revolver", "Abbey Road"))
#' find_wikipedia_matches(albums, name_col = "title")
#' }
#'
#' @importFrom utils URLencode
#' @export
find_wikipedia_matches <- function(x, n = 6, name_col = "name",
                                   lang = "en", delay = 0.5) {
  if (is.data.frame(x)) {
    stopifnot(name_col %in% names(x))
    queries <- as.character(x[[name_col]])
  } else {
    queries <- as.character(x)
  }

  out <- vector("list", length(queries))
  for (i in seq_along(queries)) {
    if (i > 1 && delay > 0) Sys.sleep(delay)

    hits <- search_wikipedia_all(queries[[i]], lang = lang, limit = n)

    if (nrow(hits) == 0) {
      out[[i]] <- tibble::tibble(
        query = queries[[i]],
        rank = NA_integer_,
        match = NA,
        title = NA_character_,
        url = NA_character_,
        snippet = NA_character_
      )
    } else {
      norm_query <- tolower(gsub("\\s+", "", queries[[i]]))
      norm_title <- tolower(gsub("\\s+", "", hits$title))
      out[[i]] <- tibble::tibble(
        query = queries[[i]],
        rank = seq_len(nrow(hits)),
        match = !is.na(norm_title) & nzchar(norm_query) & norm_title == norm_query,
        title = hits$title,
        url = hits$url,
        snippet = hits$snippet
      )
    }
  }

  dplyr::bind_rows(out)
}
