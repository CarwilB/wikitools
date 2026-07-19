# wikiblame.R
# Functions for tracing the origin of text in Wikipedia revision history.
# Functions: get_revision_history_map, get_revision_text_safe,
#            find_sentence_insertion, track_wikipedia_sentences

#' Fetch the Full Revision History of a Wikipedia Article
#'
#' Returns a data frame of all revisions for a Wikipedia article, sorted
#' oldest to newest. Handles MediaWiki API pagination automatically, so
#' articles with thousands of revisions are fully retrieved.
#'
#' @param article Character. Wikipedia article title.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A data frame with columns `revid` (integer), `timestamp`
#'   (character, ISO 8601), and `user` (character). Rows are sorted
#'   ascending by timestamp.
#'
#' @examples
#' \dontrun{
#' map <- get_revision_history_map("Margaret Mead")
#' head(map)
#' }
#'
#' @seealso [find_sentence_insertion()], [track_wikipedia_sentences()]
#' @export
get_revision_history_map <- function(article, lang = "en") {
  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")
  all_revisions <- list()
  continue_token <- NULL

  message("Mapping revision history (this may take a moment for long articles)...")

  repeat {
    params <- list(
      action  = "query",
      prop    = "revisions",
      titles  = article,
      rvprop  = "ids|timestamp|user",
      rvlimit = "500",
      format  = "json"
    )

    if (!is.null(continue_token)) {
      params$rvcontinue <- continue_token
    }

    resp <- httr::GET(api_url, query = params, httr::user_agent("R-wikitools/1.0"))
    res  <- jsonlite::fromJSON(
      httr::content(resp, "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )

    page_id <- names(res$query$pages)[1]
    revs    <- res$query$pages[[page_id]]$revisions
    if (is.null(revs)) break

    all_revisions <- c(all_revisions, revs)

    continue_token <- res$`continue`$rvcontinue
    if (is.null(continue_token)) break
  }

  df <- do.call(rbind, lapply(all_revisions, function(x) {
    data.frame(revid = x$revid, timestamp = x$timestamp,
               user = x$user, stringsAsFactors = FALSE)
  }))

  df[order(df$timestamp), ]
}

#' Fetch Wikitext for a Specific Revision Safely
#'
#' Retrieves the raw wikitext of a Wikipedia revision by ID. Handles both
#' the modern slot-based API response format and the legacy `"*"` field.
#' Returns `NULL` rather than erroring if the revision is inaccessible.
#'
#' @param revid Numeric or character. Wikipedia revision ID.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A character string of wikitext, or `NULL` if not retrievable.
#'
#' @seealso [find_sentence_insertion()], [get_wikitext_by_revid()]
#' @keywords internal
get_revision_text_safe <- function(revid, lang = "en") {
  api_url <- paste0("https://", lang, ".wikipedia.org/w/api.php")

  params <- list(
    action   = "query",
    prop     = "revisions",
    revids   = as.character(revid),
    rvprop   = "content",
    rvslots  = "main",
    format   = "json"
  )

  resp <- httr::GET(api_url, query = params, httr::user_agent("R-wikitools/1.0"))

  tryCatch({
    res     <- jsonlite::fromJSON(
      httr::content(resp, "text", encoding = "UTF-8"),
      simplifyVector = FALSE
    )
    page_id  <- names(res$query$pages)[1]
    rev_data <- res$query$pages[[page_id]]$revisions[[1]]

    content <- rev_data$slots$main$content
    if (is.null(content)) content <- rev_data$slots$main[["*"]]
    if (is.null(content)) content <- rev_data[["*"]]
    content
  }, error = function(e) NULL)
}

#' Find the Revision Where a Sentence Was First Inserted
#'
#' Uses binary search over a Wikipedia article's revision history to identify
#' the revision in which a given sentence (or substring) first appears. Makes
#' one API call per binary-search step, so an article with 1,000 revisions
#' requires at most ~10 calls.
#'
#' @param article Character. Wikipedia article title.
#' @param sentence Character. The exact text to search for (case-sensitive,
#'   literal match).
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @param history_map Data frame as returned by [get_revision_history_map()].
#'   If `NULL`, the history is fetched automatically — pass a pre-fetched map
#'   when searching for multiple sentences in the same article.
#' @return A one-row data frame with columns `revid`, `timestamp`, and `user`
#'   for the revision that first contains `sentence`, or `NULL` if the sentence
#'   is not found in the revision history.
#'
#' @examples
#' \dontrun{
#' result <- find_sentence_insertion("Anthropology", "the scientific study")
#' }
#'
#' @seealso [track_wikipedia_sentences()], [get_revision_history_map()]
#' @export
find_sentence_insertion <- function(article, sentence, lang = "en",
                                    history_map = NULL) {
  if (is.null(history_map)) {
    history_map <- get_revision_history_map(article, lang)
  }

  n <- nrow(history_map)
  if (n == 0) stop("No revisions found.")

  low       <- 1L
  high      <- n
  found_idx <- -1L

  message("Searching through ", n, " revisions using binary search...")

  while (low <= high) {
    mid <- floor((low + high) / 2)
    text <- get_revision_text_safe(history_map$revid[mid], lang)

    if (is.null(text)) {
      message("Warning: could not retrieve revision ", history_map$revid[mid])
      exists <- FALSE
    } else {
      exists <- stringr::str_detect(text, stringr::fixed(sentence))
    }

    if (isTRUE(exists)) {
      found_idx <- mid
      high <- mid - 1L
    } else {
      low <- mid + 1L
    }
    cat(".")
  }
  cat("\n")

  if (found_idx != -1L) {
    result <- history_map[found_idx, ]
    message("Sentence first found in revision ", result$revid,
            " by ", result$user, " on ", result$timestamp)
    return(result)
  }

  message("Sentence not found. Note: search is case-sensitive and literal.")
  NULL
}

# Internal helper used by track_wikipedia_sentences()
.find_sentence_with_map <- function(sentence, article, history_map, lang = "en") {
  message("Searching for: ", substr(sentence, 1, 40), "...")

  low       <- 1L
  high      <- nrow(history_map)
  found_idx <- -1L

  while (low <= high) {
    mid  <- floor((low + high) / 2)
    text <- get_revision_text_safe(history_map$revid[mid], lang)
    exists <- !is.null(text) &&
      isTRUE(stringr::str_detect(text, stringr::fixed(sentence)))

    if (exists) {
      found_idx <- mid
      high <- mid - 1L
    } else {
      low <- mid + 1L
    }
  }

  if (found_idx != -1L) {
    history_map[found_idx, ]
  } else {
    data.frame(revid = NA_integer_, timestamp = NA_character_,
               user = NA_character_, stringsAsFactors = FALSE)
  }
}

#' Track Insertion Dates for Multiple Wikipedia Sentences
#'
#' Fetches the revision history once for an article, then binary-searches for
#' each sentence in `sentence_list`, returning a tidy data frame with one row
#' per sentence recording who added it and when.
#'
#' @param article Character. Wikipedia article title.
#' @param sentence_list Character vector of sentences (or substrings) to
#'   locate. Each is searched with a case-sensitive literal match.
#' @param lang Character. Wikipedia language code (default `"en"`).
#' @return A data frame with columns:
#'   \describe{
#'     \item{`original_sentence`}{The input sentence.}
#'     \item{`added_by`}{Wikipedia username of the editor who inserted it, or
#'       `NA` if not found.}
#'     \item{`date_added`}{ISO 8601 timestamp of that revision, or `NA`.}
#'     \item{`revision_id`}{Revision ID integer, or `NA`.}
#'   }
#'
#' @examples
#' \dontrun{
#' sentences <- c(
#'   "is the scientific study of humanity",
#'   "a method of analysing social or cultural interaction"
#' )
#' track_wikipedia_sentences("Anthropology", sentences)
#' }
#'
#' @seealso [find_sentence_insertion()], [get_revision_history_map()]
#' @export
track_wikipedia_sentences <- function(article, sentence_list, lang = "en") {
  history_map <- get_revision_history_map(article, lang)

  purrr::map(sentence_list, function(s) {
    res <- .find_sentence_with_map(s, article, history_map, lang)
    data.frame(
      original_sentence = s,
      added_by          = res$user,
      date_added        = res$timestamp,
      revision_id       = res$revid,
      stringsAsFactors  = FALSE
    )
  }) |> dplyr::bind_rows()
}
