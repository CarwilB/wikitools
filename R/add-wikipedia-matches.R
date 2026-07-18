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
#' A result is flagged as `wikipedia_match = TRUE` only when the top search
#' title matches the query exactly after stripping whitespace and lowercasing
#' both strings. This distinguishes an exact title match (e.g., searching
#' `"Tracy K. Smith"` and receiving `"Tracy K. Smith"`) from a related result
#' (e.g., receiving `"Tracy K. Smith (poet)"`).
#'
#' @param df A data frame or tibble containing the source names.
#' @param name_col Character. Name of the column containing search strings.
#'   Default `"name"`.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @param delay Numeric. Seconds to pause between requests (default `0.5`).
#'   Set to `0` in tests or batch jobs where rate-limiting is handled elsewhere.
#' @param limit Integer. Maximum number of search results requested per query
#'   (default `5`). Only the top result is used.
#' @return The input data frame with five appended columns:
#'   \describe{
#'     \item{wikipedia_found}{Logical. `TRUE` if any search result was returned.}
#'     \item{wikipedia_match}{Logical. `TRUE` if the top result title matches
#'       the query exactly (case- and whitespace-insensitive).}
#'     \item{wikipedia_title}{Character. Title of the top search result, or `NA`.}
#'     \item{wikipedia_url}{Character. Full Wikipedia URL of the top result, or `NA`.}
#'     \item{wikipedia_snippet}{Character. HTML snippet from the search result, or `NA`.}
#'   }
#'
#' @examples
#' \dontrun{
#' poets <- tibble::tibble(name = c("Tracy K. Smith", "Tishani Doshi"))
#' add_wikipedia_matches(poets)
#' }
#'
#' @importFrom utils URLencode
#' @export
add_wikipedia_matches <- function(df, name_col = "name", lang = "en", delay = 0.5, limit = 5) {
  stopifnot(is.data.frame(df), name_col %in% names(df))
  names_vec <- as.character(df[[name_col]])

  results <- vector("list", length(names_vec))
  for (i in seq_along(names_vec)) {
    if (i > 1 && delay > 0) Sys.sleep(delay)

    res_i <- tryCatch(
      search_wikipedia_one(names_vec[[i]], lang = lang, limit = limit),
      error = function(e) list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_)
    )

    matched <- FALSE
    if (isTRUE(res_i$found) && !is.na(res_i$title)) {
      norm_query <- tolower(gsub("\\s+", "", names_vec[[i]]))
      norm_title <- tolower(gsub("\\s+", "", res_i$title))
      matched <- nzchar(norm_query) && identical(norm_query, norm_title)
    }

    results[[i]] <- list(
      wikipedia_found   = isTRUE(res_i$found),
      wikipedia_match   = isTRUE(matched),
      wikipedia_title   = if (isTRUE(res_i$found)) res_i$title   else NA_character_,
      wikipedia_url     = if (isTRUE(res_i$found)) res_i$url     else NA_character_,
      wikipedia_snippet = if (isTRUE(res_i$found)) res_i$snippet else NA_character_
    )
  }

  results_df <- dplyr::bind_rows(lapply(results, as.data.frame, stringsAsFactors = FALSE))

  out <- dplyr::bind_cols(df, results_df)
  out$wikipedia_found <- as.logical(out$wikipedia_found)
  out$wikipedia_match <- as.logical(out$wikipedia_match)
  if (inherits(df, "tbl_df")) out <- tibble::as_tibble(out)
  out
}
