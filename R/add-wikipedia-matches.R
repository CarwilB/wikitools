#' Add Wikipedia Search Matches to a Data Frame
#'
#' @title Add Wikipedia Search Matches to a Data Frame
#' @description Searches Wikipedia for each value in a specified name column and
#'   appends match metadata columns. Uses `WikipediR` when available and falls
#'   back to direct MediaWiki API calls via `httr`/`jsonlite`.
#' @param df A data frame or tibble containing the source names.
#' @param name_col Character. Name of the column containing search strings.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @param delay Numeric. Seconds to wait between requests (default `0.5`).
#' @param limit Integer. Maximum number of search results requested per query.
#' @return The input data frame with appended columns:
#'   `wikipedia_found`, `wikipedia_match`, `wikipedia_title`,
#'   `wikipedia_url`, and `wikipedia_snippet`.
#' @importFrom utils URLencode
#' @importFrom tibble as_tibble
#' @export
add_wikipedia_matches <- function(df, name_col = "name", lang = "en", delay = 0.5, limit = 5) {
  stopifnot(is.data.frame(df), name_col %in% names(df))
  names_vec <- as.character(df[[name_col]])

  search_wikipedia_one <- function(query, lang = "en", limit = 5) {
    if (is.na(query) || nzchar(trimws(query)) == FALSE) {
      return(list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_))
    }

    res <- NULL
    if (requireNamespace("WikipediR", quietly = TRUE)) {
      try({
        res <- WikipediR::page_search(
          language = lang,
          project = "wikipedia",
          query = query,
          limit = limit
        )
      }, silent = TRUE)
    }

    if (is.null(res) || !is.list(res) || is.null(res$query) || is.null(res$query$search)) {
      if (!requireNamespace("httr", quietly = TRUE) || !requireNamespace("jsonlite", quietly = TRUE)) {
        stop(
          "WikipediR not available and httr/jsonlite not installed for fallback. ",
          "Install one of these: install.packages('WikipediR') or install.packages(c('httr','jsonlite'))."
        )
      }

      api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")
      resp <- httr::GET(api_url, query = list(
        action = "query",
        list = "search",
        srsearch = query,
        srlimit = limit,
        format = "json"
      ))

      if (httr::status_code(resp) >= 400) {
        return(list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_))
      }

      txt <- httr::content(resp, as = "text", encoding = "UTF-8")
      res <- jsonlite::fromJSON(txt, simplifyVector = FALSE)
    }

    search_hits <- NULL
    if (!is.null(res$query$search)) {
      search_hits <- res$query$search
    } else if (!is.null(res$search)) {
      search_hits <- res$search
    }

    if (is.null(search_hits) || length(search_hits) == 0) {
      return(list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_))
    }

    top <- search_hits[[1]]
    top_title <- if (!is.null(top$title)) as.character(top$title) else NA_character_
    top_snippet <- if (!is.null(top$snippet)) as.character(top$snippet) else NA_character_

    title_for_url <- gsub(" ", "_", top_title)
    url <- paste0(
      "https://", lang, ".wikipedia.org/wiki/",
      utils::URLencode(title_for_url, reserved = TRUE)
    )

    list(found = TRUE, title = top_title, url = url, snippet = top_snippet)
  }

  results <- vector("list", length(names_vec))
  for (i in seq_along(names_vec)) {
    nm <- names_vec[i]
    if (i > 1 && delay > 0) {
      Sys.sleep(delay)
    }

    res_i <- tryCatch(
      search_wikipedia_one(nm, lang = lang, limit = limit),
      error = function(e) list(found = FALSE, title = NA_character_, url = NA_character_, snippet = NA_character_)
    )

    matched <- FALSE
    if (isTRUE(res_i$found) && !is.na(res_i$title)) {
      norm_query <- tolower(gsub("\\s+", "", nm))
      norm_title <- tolower(gsub("\\s+", "", res_i$title))
      matched <- nzchar(norm_query) && nzchar(norm_title) && identical(norm_query, norm_title)
    }

    results[[i]] <- list(
      wikipedia_found = isTRUE(res_i$found),
      wikipedia_match = isTRUE(matched),
      wikipedia_title = if (isTRUE(res_i$found)) res_i$title else NA_character_,
      wikipedia_url = if (isTRUE(res_i$found)) res_i$url else NA_character_,
      wikipedia_snippet = if (isTRUE(res_i$found)) res_i$snippet else NA_character_
    )
  }

  results_df <- do.call(rbind, lapply(results, function(x) as.data.frame(x, stringsAsFactors = FALSE)))
  if (inherits(df, "tbl_df") && requireNamespace("tibble", quietly = TRUE)) {
    results_tbl <- tibble::as_tibble(results_df)
  } else {
    results_tbl <- results_df
  }

  out <- cbind(df, results_tbl)
  out$wikipedia_found <- as.logical(out$wikipedia_found)
  out$wikipedia_match <- as.logical(out$wikipedia_match)
  out
}
