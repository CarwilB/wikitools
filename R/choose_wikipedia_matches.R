#' Check for an Interactive Session
#'
#' Thin wrapper around [interactive()] so tests can mock the interactivity
#' check (bindings in the base namespace cannot be mocked reliably).
#'
#' @return Logical, from [interactive()].
#' @keywords internal
is_interactive <- function() {
  interactive()
}

#' Fetch Short Descriptions for Wikipedia Articles
#'
#' Internal helper used by [choose_wikipedia_matches()]. Retrieves the short
#' description (the Wikidata-sourced subtitle shown under article titles in
#' the Wikipedia apps) for a set of article titles via the MediaWiki
#' `prop=description` API. Titles are batched into groups of 50 per request,
#' the API maximum.
#'
#' @param titles Character vector of Wikipedia article titles.
#' @param lang Character. Wikipedia language code.
#' @return A named character vector mapping title to short description.
#'   Titles with no description map to `NA_character_`.
#' @keywords internal
get_short_descriptions <- function(titles, lang = "en") {
  titles <- unique(titles[!is.na(titles)])
  if (length(titles) == 0) {
    return(stats::setNames(character(), character()))
  }

  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")
  out <- stats::setNames(rep(NA_character_, length(titles)), titles)

  for (batch in split(titles, ceiling(seq_along(titles) / 50))) {
    resp <- tryCatch(
      httr::GET(api_url, query = list(
        action = "query",
        prop   = "description",
        titles = paste(batch, collapse = "|"),
        format = "json"
      )),
      error = function(e) NULL
    )
    if (is.null(resp) || httr::status_code(resp) >= 400) next

    json <- jsonlite::fromJSON(
      httr::content(resp, as = "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )
    pages <- json$query$pages
    if (is.null(pages)) next

    for (page in pages) {
      if (!is.null(page$title) && page$title %in% titles) {
        out[[page$title]] <- if (!is.null(page$description)) {
          as.character(page$description)
        } else {
          NA_character_
        }
      }
    }
  }

  out
}

#' Interactively Choose Wikipedia Articles from Search Candidates
#'
#' For each search string, shows the top `n` Wikipedia search hits (from
#' [find_wikipedia_matches()]) together with each article's short
#' description in an interactive [utils::menu()], and records the article
#' the user selects. Intended for cases where the top search hit is not
#' reliably the intended article -- for example, album titles that also name
#' a film or song.
#'
#' @param x Character vector of search strings, or a data frame containing
#'   `name_col`.
#' @param n Integer. Number of search hits shown per string (default `6`).
#' @param name_col Character. When `x` is a data frame, the name of the
#'   column containing search strings. Ignored when `x` is a character
#'   vector.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @param delay Numeric. Seconds to pause between search requests
#'   (default `0.5`). Set to `0` when rate-limiting is handled elsewhere.
#' @return A tibble with one row per search string and columns:
#'   \describe{
#'     \item{query}{Character. The search string.}
#'     \item{found}{Logical. `TRUE` if any search hits were returned.}
#'     \item{chosen}{Logical. `TRUE` if the user selected a hit; `FALSE`
#'       if the user chose "None of these" or no hits were available.}
#'     \item{rank}{Integer. Rank of the chosen hit in the search results,
#'       or `NA`.}
#'     \item{title}{Character. Title of the chosen article, or `NA`.}
#'     \item{url}{Character. Full Wikipedia URL of the chosen article,
#'       or `NA`.}
#'     \item{description}{Character. Short description of the chosen
#'       article, or `NA`.}
#'   }
#'
#' @examples
#' \dontrun{
#' choose_wikipedia_matches(c("Revolver", "Let It Be"))
#'
#' albums <- tibble::tibble(title = c("Revolver", "Abbey Road"))
#' choices <- choose_wikipedia_matches(albums, name_col = "title")
#' }
#'
#' @export
choose_wikipedia_matches <- function(x, n = 6, name_col = "name",
                                     lang = "en", delay = 0.5) {
  if (!is_interactive()) {
    stop("`choose_wikipedia_matches()` requires an interactive session.",
         call. = FALSE)
  }

  candidates <- find_wikipedia_matches(
    x, n = n, name_col = name_col, lang = lang, delay = delay
  )
  queries <- unique(candidates$query)

  descriptions <- get_short_descriptions(candidates$title, lang = lang)
  candidates$description <- unname(descriptions[candidates$title])

  results <- vector("list", length(queries))
  for (i in seq_along(queries)) {
    hits <- candidates[candidates$query == queries[[i]] & !is.na(candidates$rank), ]

    if (nrow(hits) == 0) {
      message(sprintf("No Wikipedia results for \"%s\"; skipping.", queries[[i]]))
      results[[i]] <- tibble::tibble(
        query = queries[[i]], found = FALSE, chosen = FALSE,
        rank = NA_integer_, title = NA_character_,
        url = NA_character_, description = NA_character_
      )
      next
    }

    choices <- sprintf(
      "%s%s",
      hits$title,
      ifelse(is.na(hits$description), "", paste0(" \u2014 ", hits$description)) # \u2014 = em dash
    )
    none_label <- "None of these (skip)"
    pick <- utils::menu(
      c(choices, none_label),
      title = sprintf("Which article matches \"%s\"?", queries[[i]])
    )

    if (pick == 0 || pick == length(choices) + 1) {
      results[[i]] <- tibble::tibble(
        query = queries[[i]], found = TRUE, chosen = FALSE,
        rank = NA_integer_, title = NA_character_,
        url = NA_character_, description = NA_character_
      )
    } else {
      hit <- hits[pick, ]
      results[[i]] <- tibble::tibble(
        query = queries[[i]], found = TRUE, chosen = TRUE,
        rank = hit$rank, title = hit$title,
        url = hit$url, description = hit$description
      )
    }
  }

  dplyr::bind_rows(results)
}
