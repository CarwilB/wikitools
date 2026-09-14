#' Search Wikipedia for One Query
#'
#' Internal helper called row-wise by [add_wikipedia_matches()].
#' Uses the MediaWiki search API via `httr` and `jsonlite`.
#'
#' @param query Character. Search string.
#' @param lang Character. Wikipedia language code.
#' @param limit Integer. Maximum number of search results to request.
#' @return A named list with elements `found` (logical), `title`, `url`, and
#'   `snippet` (all character). Returns `found = FALSE` with `NA` fields when
#'   the query is blank, the search returns no results, or a request error occurs.
#' @keywords internal
search_wikipedia_one <- function(query, lang = "en", limit = 5) {
  if (is.na(query) || !nzchar(trimws(query))) {
    return(list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_))
  }

  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")
  resp <- httr::GET(api_url, query = list(
    action   = "query",
    list     = "search",
    srsearch = query,
    srlimit  = limit,
    format   = "json"
  ))

  if (httr::status_code(resp) >= 400) {
    return(list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_))
  }

  json <- jsonlite::fromJSON(
    httr::content(resp, as = "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )
  hits <- json$query$search

  if (is.null(hits) || length(hits) == 0) {
    return(list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_))
  }

  top       <- hits[[1]]
  top_title <- if (!is.null(top$title)) as.character(top$title) else NA_character_
  top_snip  <- if (!is.null(top$snippet)) as.character(top$snippet) else NA_character_
  url       <- paste0("https://", lang, ".wikipedia.org/wiki/",
                      utils::URLencode(gsub(" ", "_", top_title), reserved = TRUE))

  list(found = TRUE, title = top_title, url = url, snippet = top_snip)
}

#' Add Wikipedia Search Matches to a Data Frame
#'
#' Searches Wikipedia for each value in a specified name column and appends
#' five match-metadata columns to the input data frame. Uses the MediaWiki
#' search API via `httr` and `jsonlite`.
#'
#' A result is flagged as a match only when the top search title matches the
#' query exactly after stripping whitespace and lowercasing both strings.
#' This distinguishes an exact title match (e.g., searching
#' `"Tracy K. Smith"` and receiving `"Tracy K. Smith"`) from a related result
#' (e.g., receiving `"Tracy K. Smith (poet)"`).
#'
#' @param df A data frame or tibble containing the source names.
#' @param name_col Character. Name of the column containing search strings.
#'   Default `"name"`.
#' @param lang Character vector. One or more Wikipedia language codes
#'   (default `"en"`). When more than one code is supplied, each name is
#'   searched once per language and the results for every language are
#'   appended to the same output data frame, side by side. Supplying more
#'   than one language automatically forces `.langname = TRUE` (with a
#'   message) so the resulting columns don't collide.
#' @param delay Numeric. Seconds to pause between requests (default `0.5`).
#'   Set to `0` in tests or batch jobs where rate-limiting is handled elsewhere.
#'   The pause applies between consecutive requests within each language.
#' @param limit Integer. Maximum number of search results requested per query
#'   (default `5`). Only the top result is used.
#' @param .shortname Logical. If `TRUE` (default), output columns are
#'   prefixed `wp_` (e.g. `wp_found`). If `FALSE`, columns are prefixed
#'   `wikipedia_` (e.g. `wikipedia_found`).
#' @param .langname Logical. If `TRUE`, the language code is inserted into
#'   each column name (e.g. `wp_en_found` or `wikipedia_en_found`, depending
#'   on `.shortname`). Default `FALSE`. Useful when combining results from
#'   multiple language editions into the same data frame without collisions,
#'   and automatically enabled whenever `lang` has length greater than one.
#' @return The input data frame with five appended columns per language in
#'   `lang`, named according to `.shortname` and `.langname`:
#'   \describe{
#'     \item{found}{Logical. `TRUE` if any search result was returned.}
#'     \item{match}{Logical. `TRUE` if the top result title matches
#'       the query exactly (case- and whitespace-insensitive).}
#'     \item{title}{Character. Title of the top search result, or `NA`.}
#'     \item{url}{Character. Full Wikipedia URL of the top result, or `NA`.}
#'     \item{snippet}{Character. HTML snippet from the search result, or `NA`.}
#'   }
#'
#' @examples
#' \dontrun{
#' poets <- tibble::tibble(name = c("Tracy K. Smith", "Tishani Doshi"))
#' add_wikipedia_matches(poets)
#' add_wikipedia_matches(poets, .shortname = FALSE)
#' add_wikipedia_matches(poets, lang = "es", .langname = TRUE)
#'
#' # Multiple languages in one call: results land in the same tibble,
#' # e.g. wp_en_found / wp_en_match and wp_cs_found / wp_cs_match
#' add_wikipedia_matches(poets, lang = c("en", "cs"))
#' }
#'
#' @importFrom utils URLencode
#' @export
add_wikipedia_matches <- function(df, name_col = "name", lang = "en", delay = 0.5, limit = 5,
                                   .shortname = TRUE, .langname = FALSE) {
  stopifnot(is.data.frame(df), name_col %in% names(df))
  names_vec <- as.character(df[[name_col]])

  if (length(lang) > 1 && !isTRUE(.langname)) {
    message("Multiple `lang` values supplied; forcing `.langname = TRUE` to avoid column collisions.")
    .langname <- TRUE
  }

  prefix <- if (isTRUE(.shortname)) "wp" else "wikipedia"
  out <- df

  for (lg in lang) {
    results <- vector("list", length(names_vec))
    for (i in seq_along(names_vec)) {
      if (i > 1 && delay > 0) Sys.sleep(delay)

      res_i <- tryCatch(
        search_wikipedia_one(names_vec[[i]], lang = lg, limit = limit),
        error = function(e) list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_)
      )

      matched <- FALSE
      if (isTRUE(res_i$found) && !is.na(res_i$title)) {
        norm_query <- tolower(gsub("\\s+", "", names_vec[[i]]))
        norm_title <- tolower(gsub("\\s+", "", res_i$title))
        matched <- nzchar(norm_query) && identical(norm_query, norm_title)
      }

      results[[i]] <- list(
        found   = isTRUE(res_i$found),
        match   = isTRUE(matched),
        title   = if (isTRUE(res_i$found)) res_i$title   else NA_character_,
        url     = if (isTRUE(res_i$found)) res_i$url     else NA_character_,
        snippet = if (isTRUE(res_i$found)) res_i$snippet else NA_character_
      )
    }

    results_df <- dplyr::bind_rows(lapply(results, as.data.frame, stringsAsFactors = FALSE))

    col_names <- if (isTRUE(.langname)) {
      paste(prefix, lg, names(results_df), sep = "_")
    } else {
      paste(prefix, names(results_df), sep = "_")
    }
    names(results_df) <- col_names

    results_df[[col_names[1]]] <- as.logical(results_df[[col_names[1]]])
    results_df[[col_names[2]]] <- as.logical(results_df[[col_names[2]]])

    out <- dplyr::bind_cols(out, results_df)
  }

  if (inherits(df, "tbl_df")) out <- tibble::as_tibble(out)
  out
}
