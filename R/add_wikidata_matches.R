#' Search Wikidata for One Query
#'
#' Internal helper called row-wise by [add_wikidata_matches()]. Uses the
#' `wbsearchentities` action of the Wikidata API via `httr` and `jsonlite`.
#' `wbsearchentities` matches only against entity **labels and aliases** in
#' the requested language -- it does not search description text.
#'
#' @param query Character. Search string.
#' @param lang Character. Wikidata language code (used for both the `language`
#'   and `uselang` API parameters, so labels/aliases are matched and displayed
#'   in the same language).
#' @param limit Integer. Maximum number of search results to request.
#' @param type Character. Entity type to search (default `"item"`). Passed
#'   directly to the `type` parameter of `wbsearchentities` (e.g. `"item"`,
#'   `"property"`, `"lexeme"`).
#' @return A named list with elements `found` (logical), `qid`, `label`,
#'   `description`, `alias_match` (logical, `TRUE` when the top hit matched
#'   via an alias rather than the label), `match_text` (the label or alias
#'   text the API matched against), and `url` (all character except as noted).
#'   Returns `found = FALSE` with `NA`/`NA_character_` fields when the query
#'   is blank, the search returns no results, or a request error occurs.
#' @keywords internal
search_wikidata_one <- function(query, lang = "en", limit = 5, type = "item") {
  na_result <- list(
    found = FALSE, qid = NA_character_, label = NA_character_,
    description = NA_character_, alias_match = NA, match_text = NA_character_,
    url = NA_character_
  )

  if (is.na(query) || !nzchar(trimws(query))) {
    return(na_result)
  }

  api_url <- "https://www.wikidata.org/w/api.php"
  resp <- httr::GET(api_url, query = list(
    action   = "wbsearchentities",
    search   = query,
    language = lang,
    uselang  = lang,
    type     = type,
    limit    = limit,
    format   = "json"
  ))

  if (httr::status_code(resp) >= 400) {
    return(na_result)
  }

  json <- jsonlite::fromJSON(
    httr::content(resp, as = "text", encoding = "UTF-8"),
    simplifyVector = FALSE
  )
  hits <- json$search

  if (is.null(hits) || length(hits) == 0) {
    return(na_result)
  }

  top         <- hits[[1]]
  qid         <- if (!is.null(top$id))          as.character(top$id)          else NA_character_
  label       <- if (!is.null(top$label))       as.character(top$label)       else NA_character_
  description <- if (!is.null(top$description)) as.character(top$description) else NA_character_
  match_type  <- if (!is.null(top$match$type))  as.character(top$match$type)  else NA_character_
  match_text  <- if (!is.null(top$match$text))  as.character(top$match$text)  else NA_character_
  url         <- if (!is.null(top$url)) paste0("https:", top$url) else NA_character_

  list(
    found       = TRUE,
    qid         = qid,
    label       = label,
    description = description,
    alias_match = isTRUE(match_type == "alias"),
    match_text  = match_text,
    url         = url
  )
}

#' Add Wikidata Search Matches to a Data Frame
#'
#' Searches Wikidata for each value in a specified name column and appends
#' match-metadata columns to the input data frame. Uses the `wbsearchentities`
#' action of the Wikidata API via `httr` and `jsonlite`.
#'
#' Matching searches **labels and aliases only**, in the language given by
#' `lang` -- description text is never searched. This mirrors how
#' `wbsearchentities` itself works: it returns, for each hit, which field
#' (`label` or `alias`) the query matched and the exact matched text. A
#' result is flagged as a match only when that matched text equals the query
#' exactly, after stripping whitespace and lowercasing both strings -- the
#' same convention used by [add_wikipedia_matches()]. The entity's
#' description is included in the output for context only; it does not
#' affect whether a row counts as a match.
#'
#' @param df A data frame or tibble containing the source names.
#' @param name_col Character. Name of the column containing search strings.
#'   Default `"name"`.
#' @param lang Character vector. One or more Wikidata language codes
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
#' @param type Character. Wikidata entity type to search (default `"item"`).
#'   Forwarded to [search_wikidata_one()].
#' @param .shortname Logical. If `TRUE` (default), output columns are
#'   prefixed `wd_` (e.g. `wd_found`). If `FALSE`, columns are prefixed
#'   `wikidata_` (e.g. `wikidata_found`).
#' @param .langname Logical. If `TRUE`, the language code is inserted into
#'   each column name (e.g. `wd_en_found` or `wikidata_en_found`, depending
#'   on `.shortname`). Default `FALSE`. Useful when combining results from
#'   multiple languages into the same data frame without collisions, and
#'   automatically enabled whenever `lang` has length greater than one.
#' @return The input data frame with seven appended columns per language in
#'   `lang`, named according to `.shortname` and `.langname`:
#'   \describe{
#'     \item{found}{Logical. `TRUE` if any search result was returned.}
#'     \item{match}{Logical. `TRUE` if the top hit's matched label/alias
#'       text equals the query exactly (case- and whitespace-insensitive).}
#'     \item{qid}{Character. Wikidata item ID of the top hit, or `NA`.}
#'     \item{label}{Character. Label of the top hit in `lang`, or `NA`.}
#'     \item{description}{Character. Description of the top hit in `lang`,
#'       or `NA`. Informational only -- not used to determine `match`.}
#'     \item{alias_match}{Logical. `TRUE` if the top hit matched via an
#'       alias rather than the label, `NA` if no hit was found.}
#'     \item{url}{Character. Full Wikidata URL of the top hit, or `NA`.}
#'   }
#'
#' @examples
#' \dontrun{
#' poets <- tibble::tibble(name = c("Tracy K. Smith", "Tishani Doshi"))
#' add_wikidata_matches(poets)
#' add_wikidata_matches(poets, .shortname = FALSE)
#' add_wikidata_matches(poets, lang = "es", .langname = TRUE)
#'
#' # Multiple languages in one call: results land in the same tibble,
#' # e.g. wd_en_found / wd_en_match and wd_cs_found / wd_cs_match
#' add_wikidata_matches(poets, lang = c("en", "cs"))
#' }
#'
#' @seealso [add_wikipedia_matches()]
#' @export
add_wikidata_matches <- function(df, name_col = "name", lang = "en", delay = 0.5, limit = 5,
                                  type = "item", .shortname = TRUE, .langname = FALSE) {
  stopifnot(is.data.frame(df), name_col %in% names(df))
  names_vec <- as.character(df[[name_col]])

  if (length(lang) > 1 && !isTRUE(.langname)) {
    message("Multiple `lang` values supplied; forcing `.langname = TRUE` to avoid column collisions.")
    .langname <- TRUE
  }

  na_hit <- list(found = FALSE, qid = NA_character_, label = NA_character_,
                 description = NA_character_, alias_match = NA,
                 match_text = NA_character_, url = NA_character_)

  prefix <- if (isTRUE(.shortname)) "wd" else "wikidata"
  out <- df

  for (lg in lang) {
    results <- vector("list", length(names_vec))
    for (i in seq_along(names_vec)) {
      if (i > 1 && delay > 0) Sys.sleep(delay)

      res_i <- tryCatch(
        search_wikidata_one(names_vec[[i]], lang = lg, limit = limit, type = type),
        error = function(e) na_hit
      )

      matched <- FALSE
      if (isTRUE(res_i$found) && !is.na(res_i$match_text)) {
        norm_query <- tolower(gsub("\\s+", "", names_vec[[i]]))
        norm_match <- tolower(gsub("\\s+", "", res_i$match_text))
        matched <- nzchar(norm_query) && identical(norm_query, norm_match)
      }

      results[[i]] <- list(
        found       = isTRUE(res_i$found),
        match       = isTRUE(matched),
        qid         = if (isTRUE(res_i$found)) res_i$qid         else NA_character_,
        label       = if (isTRUE(res_i$found)) res_i$label       else NA_character_,
        description = if (isTRUE(res_i$found)) res_i$description else NA_character_,
        alias_match = if (isTRUE(res_i$found)) isTRUE(res_i$alias_match) else NA,
        url         = if (isTRUE(res_i$found)) res_i$url         else NA_character_
      )
    }

    results_df <- dplyr::bind_rows(lapply(results, as.data.frame, stringsAsFactors = FALSE))
    stems <- names(results_df)

    col_names <- if (isTRUE(.langname)) {
      paste(prefix, lg, stems, sep = "_")
    } else {
      paste(prefix, stems, sep = "_")
    }
    names(results_df) <- col_names

    logical_stems <- c("found", "match", "alias_match")
    for (j in seq_along(stems)) {
      if (stems[j] %in% logical_stems) {
        results_df[[col_names[j]]] <- as.logical(results_df[[col_names[j]]])
      }
    }

    out <- dplyr::bind_cols(out, results_df)
  }

  if (inherits(df, "tbl_df")) out <- tibble::as_tibble(out)
  out
}
