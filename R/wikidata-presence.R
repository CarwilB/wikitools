# wikidata-presence.R
# Wikipedia language presence analysis for Wikidata instances.
# Functions: wikidata_instance_wikipedia_presence,
#            resume_wikidata_instance_wikipedia_presence

#' Wikipedia language presence matrix for instances of a Wikidata class
#'
#' Builds a presence matrix where rows are Wikidata items (instances of a class)
#' and columns are Wikipedia language codes, indicating whether each language
#' edition of Wikipedia has an article for that item.
#'
#' Uses [get_wikidata_instances()] to retrieve items and their sitelinks, then
#' derives language presence from the `wikipedia_articles` list-column.
#'
#' @param class_qid Character. Wikidata QID of the class (e.g. `"Q5"` for human).
#' @param languages Character vector of Wikipedia language codes to track
#'   (e.g. `c("en", "es", "pt", "qu")`), or `NULL` to auto-discover all
#'   languages present across the returned instances.
#' @param country Character. Optional Wikidata QID to filter instances by country
#'   (e.g. `"Q750"` for Bolivia). Forwarded to [get_wikidata_instances()].
#' @param limit Integer. Maximum number of instances to retrieve. Forwarded to
#'   [get_wikidata_instances()].
#' @param batch_size Integer. API batch size. Forwarded to [get_wikidata_instances()].
#' @param batch_delay Numeric. Seconds to wait between batches. Forwarded to
#'   [get_wikidata_instances()].
#' @param include_labels Logical. If `TRUE`, include `label_en` and `label_es`
#'   columns from [get_wikidata_instances()] in the output data tibble.
#' @param drop_other_langs Logical. If `TRUE` (default) and `languages` is not
#'   `NULL`, sitelinks for languages not in `languages` are ignored.
#' @param debug Logical. If `TRUE`, attach a `$debug` element to the return
#'   value with notes on handling of missing/deleted items.
#'
#' @return A named list with three elements:
#'   \describe{
#'     \item{`instances`}{Tibble returned by [get_wikidata_instances()].}
#'     \item{`presence`}{Logical matrix `[n_items × n_languages]` indicating
#'       presence in each Wikipedia edition.}
#'     \item{`data`}{Tibble with `qid` (plus optional label columns) followed
#'       by one integer (0/1) column per language.}
#'   }
#'
#' @examples
#' \dontrun{
#' res <- wikidata_instance_wikipedia_presence(
#'   class_qid = "Q5",
#'   languages = c("en", "es", "pt", "de", "qu"),
#'   limit = 500
#' )
#' head(res$data)
#'
#' # Auto-discover all Wikipedia language codes present in sitelinks
#' res2 <- wikidata_instance_wikipedia_presence(
#'   class_qid = "Q5",
#'   languages = NULL,
#'   limit = 200
#' )
#' }
#'
#' @seealso [get_wikidata_instances()], [resume_wikidata_instance_wikipedia_presence()]
#' @export
wikidata_instance_wikipedia_presence <- function(class_qid,
                                                 languages = NULL,
                                                 country = NULL,
                                                 limit = 1000,
                                                 batch_size = 50,
                                                 batch_delay = 1,
                                                 include_labels = TRUE,
                                                 drop_other_langs = TRUE,
                                                 debug = FALSE) {
  stopifnot(is.character(class_qid), length(class_qid) == 1)
  if (!is.null(languages)) stopifnot(is.character(languages), length(languages) >= 1)

  inst <- get_wikidata_instances(
    class_qid   = class_qid,
    country     = country,
    languages   = c("en", "es"),
    limit       = limit,
    batch_size  = batch_size,
    batch_delay = batch_delay
  )

  dbg <- list()
  if (isTRUE(debug)) {
    dbg$note <- paste(
      "If items are reported as 'missing or not found', it is usually because",
      "wbgetentities returned an entity with missing=''. This can happen for",
      "deleted or merged items, or transient API issues."
    )
  }

  if (nrow(inst) == 0) {
    langs <- if (is.null(languages)) character(0) else languages
    presence <- matrix(FALSE, nrow = 0, ncol = length(langs),
                       dimnames = list(character(0), langs))
    out <- list(instances = inst, presence = presence, data = tibble::tibble())
    if (isTRUE(debug)) out$debug <- dbg
    return(out)
  }

  if (!"qid" %in% names(inst)) stop("get_wikidata_instances() result lacks `qid`.")
  if (!"wikipedia_articles" %in% names(inst)) {
    stop("get_wikidata_instances() result lacks `wikipedia_articles` list-column.")
  }

  # Parse language codes from "en: Title" strings in the wikipedia_articles column
  lang_sets <- purrr::map(inst$wikipedia_articles, function(x) {
    if (is.null(x) || length(x) == 0) return(character(0))
    langs <- stringr::str_match(x, "^([a-z0-9-]+):\\s")[, 2]
    unique(langs[!is.na(langs)])
  })

  if (is.null(languages)) {
    languages <- sort(unique(unlist(lang_sets, use.names = FALSE)))
  } else if (isTRUE(drop_other_langs)) {
    lang_sets <- purrr::map(lang_sets, intersect, languages)
  }

  qids <- inst$qid
  presence <- matrix(FALSE, nrow = length(qids), ncol = length(languages),
                     dimnames = list(qids, languages))

  for (i in seq_along(qids)) {
    ls <- lang_sets[[i]]
    if (length(ls)) presence[i, intersect(ls, languages)] <- TRUE
  }

  base_cols <- dplyr::select(inst, qid)
  if (isTRUE(include_labels)) {
    label_cols <- intersect(names(inst), c("label_en", "label_es"))
    if (length(label_cols)) {
      base_cols <- dplyr::bind_cols(base_cols, inst[, label_cols, drop = FALSE])
    }
  }

  lang_df <- tibble::as_tibble(as.data.frame(1L * presence, check.names = FALSE))
  out_df <- dplyr::bind_cols(base_cols, lang_df)

  out <- list(instances = inst, presence = presence, data = out_df)
  if (isTRUE(debug)) out$debug <- dbg
  out
}

#' Resume a partially completed Wikipedia presence query
#'
#' If a prior call to [wikidata_instance_wikipedia_presence()] was interrupted,
#' pass its partial result here to fetch only the missing instances and rebuild
#' the full presence matrix.
#'
#' @param partial_result List previously returned by
#'   [wikidata_instance_wikipedia_presence()]. Must contain `$instances` with a
#'   `qid` column.
#' @param class_qid See [wikidata_instance_wikipedia_presence()].
#' @param languages See [wikidata_instance_wikipedia_presence()].
#' @param country See [wikidata_instance_wikipedia_presence()].
#' @param limit See [wikidata_instance_wikipedia_presence()].
#' @param batch_size See [wikidata_instance_wikipedia_presence()].
#' @param batch_delay See [wikidata_instance_wikipedia_presence()].
#' @param include_labels See [wikidata_instance_wikipedia_presence()].
#' @param drop_other_langs See [wikidata_instance_wikipedia_presence()].
#'
#' @return Same structure as [wikidata_instance_wikipedia_presence()].
#'
#' @seealso [wikidata_instance_wikipedia_presence()], [resume_get_wikidata_instances()]
#' @export
resume_wikidata_instance_wikipedia_presence <- function(partial_result,
                                                        class_qid,
                                                        languages = NULL,
                                                        country = NULL,
                                                        limit = 1000,
                                                        batch_size = 50,
                                                        batch_delay = 1,
                                                        include_labels = TRUE,
                                                        drop_other_langs = TRUE) {
  if (is.null(partial_result$instances) ||
      !"qid" %in% names(partial_result$instances)) {
    stop("partial_result must be a list with $instances containing a 'qid' column")
  }

  inst_full <- resume_get_wikidata_instances(
    partial_result = partial_result$instances,
    class_qid      = class_qid,
    country        = country,
    languages      = c("en", "es"),
    limit          = limit,
    batch_size     = batch_size,
    batch_delay    = batch_delay
  )

  if (!"wikipedia_articles" %in% names(inst_full)) {
    stop("get_wikidata_instances() result lacks `wikipedia_articles` list-column.")
  }

  lang_sets <- purrr::map(inst_full$wikipedia_articles, function(x) {
    if (is.null(x) || length(x) == 0) return(character(0))
    langs <- stringr::str_match(x, "^([a-z0-9-]+):\\s")[, 2]
    unique(langs[!is.na(langs)])
  })

  if (is.null(languages)) {
    languages <- sort(unique(unlist(lang_sets, use.names = FALSE)))
  } else if (isTRUE(drop_other_langs)) {
    lang_sets <- purrr::map(lang_sets, intersect, languages)
  }

  qids <- inst_full$qid
  presence <- matrix(FALSE, nrow = length(qids), ncol = length(languages),
                     dimnames = list(qids, languages))

  for (i in seq_along(qids)) {
    ls <- lang_sets[[i]]
    if (length(ls)) presence[i, intersect(ls, languages)] <- TRUE
  }

  base_cols <- dplyr::select(inst_full, qid)
  if (isTRUE(include_labels)) {
    label_cols <- intersect(names(inst_full), c("label_en", "label_es"))
    if (length(label_cols)) {
      base_cols <- dplyr::bind_cols(base_cols, inst_full[, label_cols, drop = FALSE])
    }
  }

  lang_df <- tibble::as_tibble(as.data.frame(1L * presence, check.names = FALSE))
  out_df <- dplyr::bind_cols(base_cols, lang_df)

  list(instances = inst_full, presence = presence, data = out_df)
}
