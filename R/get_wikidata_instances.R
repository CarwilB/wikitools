# Suppress R CMD check warnings for data frame column names used in dplyr operations
#' @keywords internal
"_PACKAGE"

utils::globalVariables(c("qid"))

# ---- add_wikidata_property --------------------------------------------------

#' Add a Wikidata Property to a Data Frame
#'
#' @title Add a Wikidata Property to a Data Frame
#' @description Fetches a single-valued property from Wikidata and appends it as
#'   a new column to a data frame that contains a `qid` column.
#'   Handles entity-type, string, and time values and reports when multiple
#'   statements are present for the requested property.
#'
#' @param df A data frame with a `qid` column.
#' @param property Character. Wikidata property ID (e.g., "P14142").
#' @param name Character. Name of the new column. Defaults to the property ID.
#'
#' @return The input data frame with a new character column appended.
#'
#' @examples
#' departments <- tibble::tribble(
#' ~qid,             ~label_en, ~cod.dep,
#' "Q233169",     "Beni Department",     "08",
#' "Q233917", "Cochabamba Department",     "03",
#' "Q233933",   "Tarija Department",     "06",
#' "Q235106", "Santa Cruz Department",     "07",
#' "Q235110", "Chuquisaca Department",     "01",
#' "Q235362",    "Pando Department",     "09",
#' "Q238079",   "Potosí Department",     "05",
#' "Q232784",    "La Paz Department",     "02",
#' "Q844510",             "Litoral",       NA,
#' "Q1061368",    "Oruro Department",     "04"
#' )
#' \dontrun{
#' departments |> add_wikidata_property("P14142", name = "ine_code")
#' }
#'
#' @importFrom dplyr across bind_rows distinct mutate where
#' @importFrom httr GET content status_code user_agent
#' @importFrom jsonlite fromJSON
#' @importFrom purrr compact map map_chr map_int
#' @importFrom stringr str_extract str_replace
#' @importFrom tibble tibble
#' @export
add_wikidata_property <- function(df, property, name = property) {

  if (!"qid" %in% names(df)) stop("df must contain a 'qid' column")
  if (!grepl("^P\\d+$", property)) stop("property must be in format 'P123'")

  qids <- df$qid

  values <- map_chr(qids, function(qid) {
    Sys.sleep(0.1)

    tryCatch({
      r <- GET(
        "https://www.wikidata.org/w/api.php",
        query = list(
          action = "wbgetentities",
          ids = qid,
          format = "json",
          props = "claims"
        )
      )

      entity <- fromJSON(content(r, "text", encoding = "UTF-8"))$entities[[qid]]
      claims <- entity$claims[[property]]

      if (is.null(claims) || nrow(claims) == 0) {
        return(NA_character_)
      }

      if (nrow(claims) > 1) {
        message(qid, " has ", nrow(claims), " values for ", property,
                "; using the first (rank: ", claims$rank[1], ")")
      }

      snak <- claims$mainsnak[1, ]
      dv   <- snak$datavalue[[1]]

      # Dispatch on value type
      if (is.data.frame(dv) && "amount" %in% names(dv)) {
        sub("^\\+", "", dv$amount[[1]])
      } else if (is.data.frame(dv) && "text" %in% names(dv)) {
        as.character(dv$text[[1]])
      } else if (is.data.frame(dv) && "time" %in% names(dv)) {
        as.character(dv$time[[1]])
      } else if (is.data.frame(dv) && "id" %in% names(dv)) {
        as.character(dv$id[[1]])
      } else if (is.character(dv)) {
        dv
      } else {
        as.character(dv)
      }

    }, error = function(e) {
      message("Error on ", qid, ": ", conditionMessage(e))
      NA_character_
    })
  })

  df[[name]] <- values
  df
}

#' Extract Numeric Multi-Claim Property Values
#'
#' @title Extract Numeric Multi-Claim Property Values
#' @description Internal helper that extracts value, year, and reference fields
#'   from all claims for one quantity property in a Wikidata entity.
#' @param entity A single Wikidata entity object.
#' @param pid Character. Property ID to extract (e.g., `"P1082"`).
#' @param pname Character. Output column prefix.
#' @param max_vals Integer. Maximum number of claim slots to emit.
#' @return A named list of scalar values suitable for row-binding.
#' @keywords internal

.extract_numeric_list_property <- function(entity, pid, pname, max_vals = 10) {

  # All-NA result returned when property is absent or empty
  empty_result <- function() {
    out <- list()
    out[[pname]]               <- NA_real_
    out[[paste0(pname, "_n")]] <- 0L
    for (i in seq_len(max_vals)) {
      out[[paste0(pname, "_", i)]]          <- NA_real_
      out[[paste0(pname, "_", i, "_year")]] <- NA_integer_
      out[[paste0(pname, "_", i, "_ref")]]  <- NA_character_
    }
    out
  }

  if (!pid %in% names(entity$claims)) return(empty_result())
  claims_df <- entity$claims[[pid]]
  if (is.null(claims_df) || nrow(claims_df) == 0) return(empty_result())

  n_claims <- nrow(claims_df)

  # Extract (amount, year, ref) for each claim row
  records <- lapply(seq_len(n_claims), function(i) {

    # ---- amount ----
    amount <- tryCatch({
      dv <- claims_df$mainsnak[i, ]$datavalue[[1]]
      if (is.data.frame(dv) && "amount" %in% names(dv))
        as.numeric(sub("^\\+", "", dv$amount[[1]]))
      else NA_real_
    }, error = function(e) NA_real_)

    # ---- year from P585 (point in time) qualifier ----
    year <- tryCatch({
      # qualifiers is a data.frame (one row per claim); use row indexing
      qual <- if (is.data.frame(claims_df$qualifiers)) {
        claims_df$qualifiers[i, ]
      } else {
        claims_df$qualifiers[[i]]
      }
      if (!is.null(qual) && "P585" %in% names(qual) && !is.null(qual[["P585"]])) {
        # P585 cell is a list-of-one-snak; unwrap to the snak data.frame
        p585_snaks <- qual[["P585"]]
        p585_snak  <- if (is.list(p585_snaks) && !is.data.frame(p585_snaks)) {
          p585_snaks[[1]]
        } else {
          p585_snaks
        }
        # datavalue is a data.frame with a nested $value data.frame containing $time
        dv <- p585_snak$datavalue
        time_str <- if (is.data.frame(dv) && "value" %in% names(dv) &&
                        is.data.frame(dv$value) && "time" %in% names(dv$value)) {
          dv$value$time[[1]]
        } else if (is.data.frame(dv) && "time" %in% names(dv)) {
          dv$time[[1]]
        } else if (is.list(dv) && !is.data.frame(dv)) {
          dv$value$time
        } else NULL
        if (!is.null(time_str) && !is.na(time_str))
          as.integer(regmatches(time_str, regexpr("\\d{4}", time_str)))
        else NA_integer_
      } else NA_integer_
    }, error = function(e) NA_integer_)

    # ---- ref: prefer P854 (reference URL), fallback P248 (stated in) ----
    ref <- tryCatch({
      refs <- claims_df$references[[i]]
      if (!is.null(refs) && length(refs) > 0) {
        # refs is a data.frame (one row per reference block); $snaks is a
        # data.frame of snak lists keyed by property ID
        snaks <- refs$snaks
        if (!is.null(snaks) && "P854" %in% names(snaks)) {
          # P854 is a URL string value
          dv <- snaks[["P854"]][[1]]$datavalue[[1]]
          if (is.character(dv))    dv
          else if (is.list(dv))   as.character(dv$value)
          else                    NA_character_
        } else if (!is.null(snaks) && "P248" %in% names(snaks)) {
          # P248 is an entity value
          dv  <- snaks[["P248"]][[1]]$datavalue[[1]]
          qid_val <- if (is.data.frame(dv) && "id" %in% names(dv)) dv$id[[1]]
          else if (is.list(dv))                          dv$value$id
          else                                           NA_character_
          if (!is.null(qid_val) && !is.na(qid_val)) paste0("wd:", qid_val)
          else NA_character_
        } else NA_character_
      } else NA_character_
    }, error = function(e) NA_character_)

    list(amount = amount, year = year, ref = ref)
  })

  # Sort by year descending, NAs last
  years <- sapply(records, function(r) if (is.null(r$year) || is.na(r$year)) NA_integer_ else r$year)
  ord   <- order(is.na(years), -ifelse(is.na(years), 0L, years))
  records <- records[ord]
  n <- length(records)

  # Build the flat output list
  out <- list()
  out[[pname]]               <- records[[1]]$amount   # most recent
  out[[paste0(pname, "_n")]] <- n

  for (i in seq_len(max_vals)) {
    if (i <= n) {
      out[[paste0(pname, "_", i)]]          <- records[[i]]$amount
      out[[paste0(pname, "_", i, "_year")]] <- records[[i]]$year
      out[[paste0(pname, "_", i, "_ref")]]  <- records[[i]]$ref
    } else {
      out[[paste0(pname, "_", i)]]          <- NA_real_
      out[[paste0(pname, "_", i, "_year")]] <- NA_integer_
      out[[paste0(pname, "_", i, "_ref")]]  <- NA_character_
    }
  }

  out
}

#' Extract Instance/Subclass QIDs
#'
#' @title Extract Instance/Subclass QIDs
#' @description Internal helper that extracts all P31 (instance of) or P279
#'   (subclass of) target QIDs from one entity.
#' @param entity A single Wikidata entity object.
#' @param property_id Character. Either `"P31"` or `"P279"`.
#' @return A character vector of QIDs.
#' @keywords internal

.extract_instance_or_subclass <- function(entity, property_id = "P31") {
  if ("claims" %in% names(entity) && property_id %in% names(entity$claims)) {
    p_df <- entity$claims[[property_id]]
    if (nrow(p_df) > 0) {
      map_chr(seq_len(nrow(p_df)), function(i) {
        p_df$mainsnak[i, ]$datavalue[[1]]$id
      })
    } else character(0)
  } else character(0)
}

#' Build SPARQL Query for Class Retrieval
#'
#' @title Build SPARQL Query for Class Retrieval
#' @description Internal helper that builds a SPARQL query for retrieving items
#'   by `instance of` or `subclass of` with an optional country filter.
#' @param class_qid Character class QID.
#' @param country Optional character country QID.
#' @param property_id Character. A Wikidata property ID (e.g. `"P31"`,
#'   `"P279"`, `"P39"`).
#' @param limit Integer result limit.
#' @return A character SPARQL query string.
#' @keywords internal

.build_sparql_query <- function(class_qid, country = NULL, property_id = "P31", limit = 1000) {
  if (!grepl("^P\\d+$", property_id)) {
    stop("property_id must be a Wikidata property ID in format 'P123'")
  }

  country_triple <- if (!is.null(country)) {
    sprintf("  ?item wdt:P17 wd:%s .\n", country)
  } else ""

  sprintf(
    'SELECT DISTINCT ?item WHERE {\n  ?item wdt:%s wd:%s .\n%s}\nLIMIT %d\n',
    property_id, class_qid, country_triple, limit
  )
}

#' Parse a Wikidata Entity Record
#'
#' @title Parse a Wikidata Entity Record
#' @description Internal helper that parses one Wikidata entity into a named
#'   list record for tabular binding.
#' @param entity A single Wikidata entity object.
#' @param qid Character QID for the entity.
#' @param property Optional character vector of extra property IDs.
#' @param property_names Character vector of output names for `property`.
#' @param languages Character vector of language codes.
#' @param numeric_list_properties Optional character vector of numeric-list property IDs.
#' @param numeric_list_property_names Character vector of output prefixes.
#' @param object_type Character. `"instance"` or `"subclass"`.
#' @param verbose Logical. If `TRUE`, emit detailed parsing diagnostics.
#' @return A named list representing one parsed entity row.
#' @keywords internal

.parse_entity <- function(entity, qid, property, property_names, languages,
                          numeric_list_properties     = NULL,
                          numeric_list_property_names = NULL,
                          object_type                 = "instance",
                          verbose                     = FALSE) {

  stage_error_message <- function(stage, e, relevant_data) {
    if (!verbose) return(invisible(NULL))
    error_call <- paste(deparse(conditionCall(e)), collapse = " ")
    message(
      "  .parse_entity stage '", stage, "' failed for ", qid, ": ",
      conditionMessage(e), "\n",
      "    call: ", error_call, "\n",
      "    data:\n",
      paste(capture.output(str(relevant_data, max.level = 2, list.len = 5)), collapse = "\n")
    )
  }

  # Extract labels
  labels_list <- tryCatch({
    map(languages, function(lang) {
      if (lang %in% names(entity$labels)) entity$labels[[lang]]$value
      else NA_character_
    })
  }, error = function(e) {
    stage_error_message("labels", e, entity$labels)
    rep(list(NA_character_), length(languages))
  })
  names(labels_list) <- paste0("label_", languages)

  # Extract descriptions
  descriptions_list <- tryCatch({
    map(languages, function(lang) {
      if (lang %in% names(entity$descriptions)) entity$descriptions[[lang]]$value
      else NA_character_
    })
  }, error = function(e) {
    stage_error_message("descriptions", e, entity$descriptions)
    rep(list(NA_character_), length(languages))
  })
  names(descriptions_list) <- paste0("description_", languages)

  # Extract extra properties as list columns
  extra_props <- if (!is.null(property)) {
    prop_values <- map(seq_along(property), function(i) {
      pid   <- property[i]
      pname <- property_names[i]
      vals <- tryCatch({
        if ("claims" %in% names(entity) && pid %in% names(entity$claims)) {
          p_df <- entity$claims[[pid]]
          if (nrow(p_df) > 0) {
            map_chr(seq_len(nrow(p_df)), function(j) {
              dv <- p_df$mainsnak[j, ]$datavalue[[1]]
              if (is.data.frame(dv) && "amount" %in% names(dv)) {
                sub("^\\+", "", dv$amount[[1]])
              } else if (is.data.frame(dv) && "text" %in% names(dv)) {
                as.character(dv$text[[1]])
              } else if (is.data.frame(dv) && "time" %in% names(dv)) {
                as.character(dv$time[[1]])
              } else if (is.data.frame(dv) && "id" %in% names(dv)) {
                as.character(dv$id[[1]])
              } else if (is.character(dv)) {
                dv
              } else {
                as.character(dv)
              }
            })
          } else character(0)
        } else character(0)
      }, error = function(e) {
        stage_error_message(
          paste0("property ", pid, " (", pname, ")"),
          e,
          if (!is.null(entity$claims) && pid %in% names(entity$claims)) entity$claims[[pid]] else entity$claims
        )
        character(0)
      })
      setNames(list(list(vals)), pname)
    })
    unlist(prop_values, recursive = FALSE)
  } else list()

  # Extract numeric list properties (multi-value quantities with year + ref)
  numeric_list_cols <- if (!is.null(numeric_list_properties)) {
    empty_numeric_list_result <- function(pname, max_vals = 10) {
      out <- list()
      out[[pname]]               <- NA_real_
      out[[paste0(pname, "_n")]] <- 0L
      for (k in seq_len(max_vals)) {
        out[[paste0(pname, "_", k)]]          <- NA_real_
        out[[paste0(pname, "_", k, "_year")]] <- NA_integer_
        out[[paste0(pname, "_", k, "_ref")]]  <- NA_character_
      }
      out
    }
    result <- list()
    for (i in seq_along(numeric_list_properties)) {
      pid <- numeric_list_properties[i]
      pname <- numeric_list_property_names[i]
      extracted <- tryCatch({
        if (!"claims" %in% names(entity)) {
          stop("numeric_list_properties requested but entity has no 'claims' (did you request props without 'claims'?)")
        }
        .extract_numeric_list_property(entity, pid = pid, pname = pname)
      }, error = function(e) {
        stage_error_message(
          paste0("numeric_list_property ", pid),
          e,
          if (!is.null(entity$claims) && pid %in% names(entity$claims)) entity$claims[[pid]] else entity$claims
        )
        empty_numeric_list_result(pname)
      })
      result <- c(result, extracted)
    }
    result
  } else list()

  # Extract P31 (instance of), P279 (subclass of), or P39 (position held) statements
  property_id <- switch(object_type,
    instance        = "P31",
    subclass        = "P279",
    position_held   = "P39",
    "P31"
  )
  column_name <- switch(object_type,
    instance        = "instance_of",
    subclass        = "subclass_of",
    position_held   = "position_held",
    "instance_of"
  )
  hierarchy_vals <- tryCatch({
    .extract_instance_or_subclass(entity, property_id)
  }, error = function(e) {
    stage_error_message("instance_of/hierarchy", e, entity$claims)
    character(0)
  })

  # Extract Wikipedia sitelinks
  wiki_articles <- tryCatch({
    if (!is.null(entity$sitelinks) && length(entity$sitelinks) > 0) {
      site_names <- names(entity$sitelinks)
      articles <- map_chr(site_names, function(site) {
        if (grepl("wiki$", site) && !grepl("wikivoyage|wikiquote|wikibooks", site)) {
          lang_code <- str_replace(site, "wiki$", "")
          title <- entity$sitelinks[[site]]$title
          if (!is.null(title)) paste0(lang_code, ": ", title) else NA_character_
        } else NA_character_
      })
      articles[!is.na(articles)]
    } else character(0)
  }, error = function(e) {
    stage_error_message("sitelinks", e, entity$sitelinks)
    character(0)
  })

  # Build the output list dynamically
  out <- c(
    list(qid = qid),
    labels_list,
    descriptions_list,
    extra_props,
    numeric_list_cols,
    setNames(list(list(hierarchy_vals)), column_name),
    list(wikipedia_articles = list(wiki_articles))
  )

  out
}

#' Fetch QIDs from Wikidata in Batches
#'
#' @title Fetch QIDs from Wikidata in Batches
#' @description Internal helper that calls `wbgetentities` in batches and parses
#'   each returned entity into row records.
#' @param qids Character vector of QIDs to fetch.
#' @param property Optional character vector of extra property IDs.
#' @param property_names Character vector of output names.
#' @param languages Character vector of languages for labels/descriptions.
#' @param batch_size Integer batch size.
#' @param batch_delay Numeric delay between batches.
#' @param numeric_list_properties Optional character vector of numeric-list property IDs.
#' @param numeric_list_property_names Character vector of output prefixes.
#' @param entity_props Character pipe-delimited `wbgetentities` props string.
#' @param object_type Character. `"instance"` or `"subclass"`.
#' @param verbose Logical. If `TRUE`, emit detailed parsing diagnostics.
#' @return A list of parsed entity records.
#' @keywords internal

.fetch_qids_in_batches <- function(qids, property, property_names, languages,
                                   batch_size = 20, batch_delay = 1,
                                   numeric_list_properties     = NULL,
                                   numeric_list_property_names = NULL,
                                   entity_props               = "labels|descriptions|claims|sitelinks",
                                   object_type                = "instance",
                                   verbose                    = FALSE) {

  batches    <- split(qids, ceiling(seq_along(qids) / batch_size))
  n_batches  <- length(batches)
  api_url    <- "https://www.wikidata.org/w/api.php"
  all_parsed <- vector("list", length(qids))
  idx        <- 1L

  for (b in seq_along(batches)) {
    batch <- batches[[b]]
    message("  Batch ", b, "/", n_batches,
            " (", length(batch), " items)...")

    tryCatch({
      api_response <- GET(
        url   = api_url,
        query = list(
          action = "wbgetentities",
          ids    = paste(batch, collapse = "|"),
          format = "json",
          props  = entity_props
        ),
        user_agent("WikidataR-instances-retrieval")
      )

      raw_text <- content(api_response, "text", encoding = "UTF-8")
      item_data <- fromJSON(raw_text)
      entities  <- item_data$entities

      if (verbose) {
        message("    HTTP status code: ", httr::status_code(api_response))
        message("    Raw response (first 500 chars): ", substr(raw_text, 1, 500))
        qids_in_entities <- names(entities)
        if (is.null(qids_in_entities) || length(qids_in_entities) == 0) {
          message("    QIDs in entities: <none>")
        } else {
          message("    QIDs in entities: ", paste(qids_in_entities, collapse = ", "))
        }
      }

      for (qid in batch) {
        entity <- entities[[qid]]

        missing_flag <- is.null(entity) || (is.list(entity) && "missing" %in% names(entity))

        if (missing_flag) {
          message("  Item ", qid, " missing or not found; skipping.")
          all_parsed[[idx]] <- NULL
        } else {
          all_parsed[[idx]] <- tryCatch(
            .parse_entity(entity, qid, property, property_names, languages,
                          numeric_list_properties, numeric_list_property_names,
                          object_type, verbose),
            error = function(e) {
              message("  Error parsing ", qid, ": ", e$message)
              if (verbose) {
                message("    call: ", paste(deparse(conditionCall(e)), collapse = " "))
                message(
                  "    entity structure:\n",
                  paste(capture.output(str(entity, max.level = 2, list.len = 10)), collapse = "\n")
                )
              }
              NULL
            }
          )
        }
        idx <- idx + 1L
      }
    }, error = function(e) {
      message("  Batch ", b, " failed: ", e$message,
              "\n  Items in batch: ", paste(batch, collapse = ", "))
      for (qid in batch) {
        all_parsed[[idx]] <<- NULL
        idx <<- idx + 1L
      }
    })

    if (b < n_batches) Sys.sleep(batch_delay)
  }

  compact(all_parsed)
}

#' Execute SPARQL Query and Return QIDs
#'
#' @title Execute SPARQL Query and Return QIDs
#' @description Internal helper that executes the generated SPARQL query and
#'   extracts item QIDs from the result set.
#' @param class_qid Character class QID.
#' @param country Optional character country QID.
#' @param limit Integer result limit.
#' @param property_id Character. `"P31"` or `"P279"`.
#' @return A character vector of QIDs.
#' @keywords internal

.sparql_get_qids <- function(class_qid, country, limit, property_id = "P31") {
  sparql_query <- .build_sparql_query(class_qid, country, property_id, limit)

  response <- GET(
    url   = "https://query.wikidata.org/sparql",
    query = list(query = sparql_query, format = "json"),
    user_agent("WikidataR-instances-retrieval")
  )

  if (status_code(response) != 200) {
    stop("SPARQL query failed with status: ", status_code(response))
  }

  results <- fromJSON(content(response, "text", encoding = "UTF-8"))

  if (length(results$results$bindings) == 0) {
    return(character(0))
  }

  str_extract(results$results$bindings$item$value, "Q\\d+$")
}

# ---- get_wikidata_instances --------------------------------------------------

#' Get All Instances of a Wikidata Class
#'
#' @title Get All Instances of a Wikidata Class
#' @description Retrieves all instances (P31) or subclasses (P279) of a given
#'   class from Wikidata with labels, descriptions, optional properties, and
#'   linked Wikipedia article titles.
#'
#' Items are fetched from the Wikidata API in batches of \code{batch_size}
#' (default 50, the API maximum) to avoid rate-limiting errors.
#'
#' @param class_qid Character. The Wikidata QID of the class (e.g., "Q250050")
#' @param property Character or character vector. Optional property ID(s) to
#'   retrieve as additional columns (e.g., \code{"P131"} or
#'   \code{c("P131", "P17")}). Default is \code{NULL}.
#' @param property_names Character vector. Column names to use for the extra
#'   properties. Default is \code{NULL} (use property IDs as column names).
#' @param country Character. Optional Wikidata QID of a country (e.g., "Q750"
#'   for Bolivia). Default is \code{NULL} (no country filter).
#' @param languages Character vector. Language codes for labels and descriptions.
#'   Default is c("en", "es").
#' @param limit Integer. Maximum number of results to return. Default is 1000.
#' @param batch_size Integer. Number of items per API request (max 50).
#'   Default is 50.
#' @param batch_delay Numeric. Seconds to wait between batches. Default is 1.
#' @param numeric_list_properties Character vector of property IDs (e.g.,
#'   \code{"P1082"}) whose values are Wikidata quantity statements that may
#'   have multiple claims (e.g. population figures across years). These must
#'   NOT also appear in \code{property}. For each property named \code{pname}
#'   in \code{numeric_list_property_names}, the following columns are added:
#'   \describe{
#'     \item{pname}{Most recent value (numeric; sorted by P585 year desc).}
#'     \item{pname_n}{Total number of claims (integer).}
#'     \item{pname_1 ... pname_10}{Individual values (numeric).}
#'     \item{pname_1_year ... pname_10_year}{Year from P585 qualifier (integer).}
#'     \item{pname_1_ref ... pname_10_ref}{Reference URL (P854) or
#'       \code{"wd:Qxxx"} (P248), or \code{NA} (character).}
#'   }
#' @param numeric_list_property_names Character vector. Column name prefixes
#'   for each entry in \code{numeric_list_properties}. Defaults to the
#'   property IDs if \code{NULL}.
#' @param entity_props Character. Pipe-separated list of Wikidata entity props
#'   to request from \code{wbgetentities} (e.g. "labels|sitelinks"). Default is
#'   "labels|descriptions|claims|sitelinks".
#' @param object_type Character. Controls which Wikidata property is used for
#'   the SPARQL query:
#'   \describe{
#'     \item{"instance"}{P31 (instance of) — the default.}
#'     \item{"subclass"}{P279 (subclass of).}
#'     \item{"position_held"}{P39 (position held) — retrieves items (typically
#'       persons) that have held the specified office or position. Adds a
#'       `position_held` list-column to the result.}
#'   }
#' @param verbose Logical. If `TRUE`, print SPARQL query and detailed parse diagnostics.
#'
#' @return A tibble with columns:
#'   - qid
#'   - label_<lang>, description_<lang> for each language
#'   - Columns from \code{property} and \code{numeric_list_properties}
#'   - instance_of (if object_type="instance") or subclass_of (if object_type="subclass")
#'   - wikipedia_articles
#'
#' @examples
#' get_wikidata_instances("Q250050", languages = c("en", "es"))
#'
#' get_wikidata_instances(
#'   "Q1062710",
#'   property                    = c("P131", "P17", "P14142"),
#'   property_names              = c("located_in", "country", "ine_code"),
#'   numeric_list_properties     = "P1082",
#'   numeric_list_property_names = "population"
#' )
#'
#' # Retrieve subclasses instead of instances
#' get_wikidata_instances("Q34770", object_type = "subclass")
#'
#' get_wikidata_instances("Q4193029", property = "P1448",
#'   property_names = "official_name", verbose = TRUE)
#'
#' @export
get_wikidata_instances <- function(class_qid,
                                   property                    = NULL,
                                   property_names              = NULL,
                                   country                     = NULL,
                                   languages                   = c("en", "es"),
                                   limit                       = 1000,
                                   batch_size                  = 50,
                                   batch_delay                 = 1,
                                   numeric_list_properties     = NULL,
                                   numeric_list_property_names = NULL,
                                   entity_props                = "labels|descriptions|claims|sitelinks",
                                   object_type                 = "instance",
                                   verbose                     = FALSE) {

  # Validate object_type
  if (!object_type %in% c("instance", "subclass", "position_held")) {
    stop('object_type must be "instance", "subclass", or "position_held"')
  }

  # Resolve column names for regular extra properties
  if (!is.null(property)) {
    n_prop  <- length(property)
    n_names <- length(property_names)
    if (n_names > n_prop) {
      message("property_names has more entries (", n_names, ") than property (",
              n_prop, "); extra names will be ignored.")
      property_names <- property_names[seq_len(n_prop)]
    } else if (n_names < n_prop) {
      if (n_names > 0)
        message("property_names has fewer entries (", n_names, ") than property (",
                n_prop, "); falling back to property IDs for unnamed columns.")
      property_names <- c(property_names, property[(n_names + 1):n_prop])
    }
  }

  # Resolve column name prefixes for numeric list properties
  numeric_list_properties <- as.character(numeric_list_properties)
  if (length(numeric_list_properties) > 0) {
    if (is.null(numeric_list_property_names))
      numeric_list_property_names <- numeric_list_properties
    n_nlp  <- length(numeric_list_properties)
    n_nlpn <- length(numeric_list_property_names)
    if (n_nlpn < n_nlp)
      numeric_list_property_names <- c(numeric_list_property_names,
                                       numeric_list_properties[(n_nlpn + 1):n_nlp])
    if (n_nlpn > n_nlp)
      numeric_list_property_names <- numeric_list_property_names[seq_len(n_nlp)]
  }

  # Validate input
  if (!grepl("^Q\\d+$", class_qid))
    stop("class_qid must be in format 'Q123'")
  if (!is.null(country) && !grepl("^Q\\d+$", country))
    stop("country must be in format 'Q123'")
  batch_size <- min(as.integer(batch_size), 50L)

  # Validate props requirements based on requested features
  if (!is.null(property) && length(property) > 0 && !grepl("(^|\\|)claims(\\||$)", entity_props)) {
    stop("property=... requires entity_props to include 'claims' (so we can read property values).")
  }
  if (!is.null(numeric_list_properties) && length(numeric_list_properties) > 0 && !grepl("(^|\\|)claims(\\||$)", entity_props)) {
    stop("numeric_list_properties requires entity_props to include 'claims'.")
  }

  # Determine property ID and message suffix
  property_id <- switch(object_type,
    instance      = "P31",
    subclass      = "P279",
    position_held = "P39"
  )
  type_label <- switch(object_type,
    instance      = "instances",
    subclass      = "subclasses",
    position_held = "position holders"
  )

  # Step 1: SPARQL -- get all QIDs
  if (verbose) {
    sparql_query <- .build_sparql_query(class_qid, country, property_id, limit)
    message("SPARQL query:\n", sparql_query)
  }
  qids <- .sparql_get_qids(class_qid, country, limit, property_id)

  if (length(qids) == 0) {
    message("No ", type_label, " found for ", class_qid)
    return(tibble())
  }

  message("Found ", length(qids), " ", type_label, ". Retrieving details in batches of ",
          batch_size, "...")

  # Step 2: fetch in batches
  items_data <- .fetch_qids_in_batches(
    qids, property, property_names, languages, batch_size, batch_delay,
    numeric_list_properties, numeric_list_property_names,
    entity_props = entity_props,
    object_type = object_type,
    verbose = verbose
  )

  # Convert to tibble and simplify single-value list columns
  result_df <- bind_rows(items_data) |> simplify_list_columns()

  message("Successfully retrieved ", nrow(result_df), " items")
  result_df
}

# ---- resume_get_wikidata_instances -------------------------------------------

#' Resume a Partially-Completed get_wikidata_instances() Query
#'
#' @title Resume a Partially-Completed get_wikidata_instances() Query
#' @description Continues a partially completed class retrieval by skipping
#'   already fetched QIDs and retrieving only remaining entities.
#'   Re-runs SPARQL to get the full QID list, skips already retrieved entries,
#'   fetches the remainder in batches, and returns a de-duplicated result.
#'
#' @param partial_result A tibble previously returned (or partially returned)
#'   by \code{get_wikidata_instances()}. Must contain a \code{qid} column.
#' @param class_qid Character. Same value used in the original call.
#' @param property Character vector. Same value used in the original call.
#' @param property_names Character vector. Same value used in the original call.
#' @param country Character. Same value used in the original call.
#' @param languages Character vector. Same value used in the original call.
#' @param limit Integer. Default 1000.
#' @param batch_size Integer. Items per API request (max 50). Default 50.
#' @param batch_delay Numeric. Seconds between batches. Default 1.
#' @param numeric_list_properties Character vector. Same value used in the
#'   original call. Default \code{NULL}.
#' @param numeric_list_property_names Character vector. Same value used in the
#'   original call. Default \code{NULL}.
#' @param entity_props Character. Same value used in the original call.
#'   Default "labels|descriptions|claims|sitelinks".
#' @param object_type Character. Either "instance" or "subclass". Default
#'   "instance". Must match the original call.
#' @param verbose Logical. If `TRUE`, print SPARQL query and detailed parse diagnostics.
#'
#' @return A tibble with the same columns as \code{get_wikidata_instances()},
#'   containing all items (previously retrieved + newly fetched).
#'
#' @examples
#' \dontrun{
#' # Assuming municipalities_wd is a partial result from a prior call
#' municipalities_wd <- resume_get_wikidata_instances(
#'   municipalities_wd, "Q1062710",
#'   property                    = c("P131", "P17", "P14142"),
#'   property_names              = c("located_in", "country", "ine_code"),
#'   numeric_list_properties     = "P1082",
#'   numeric_list_property_names = "population"
#' )
#' }
#'
#' @export
resume_get_wikidata_instances <- function(partial_result,
                                          class_qid,
                                          property                    = NULL,
                                          property_names              = NULL,
                                          country                     = NULL,
                                          languages                   = c("en", "es"),
                                          limit                       = 1000,
                                          batch_size                  = 50,
                                          batch_delay                 = 1,
                                          numeric_list_properties     = NULL,
                                          numeric_list_property_names = NULL,
                                          entity_props                = "labels|descriptions|claims|sitelinks",
                                          object_type                 = "instance",
                                          verbose                     = FALSE) {

  if (!"qid" %in% names(partial_result))
    stop("partial_result must contain a 'qid' column")
  if (!grepl("^Q\\d+$", class_qid))
    stop("class_qid must be in format 'Q123'")
  if (!object_type %in% c("instance", "subclass", "position_held"))
    stop('object_type must be "instance", "subclass", or "position_held"')
  batch_size <- min(as.integer(batch_size), 50L)

  # Resolve property names
  if (!is.null(property)) {
    n_prop  <- length(property)
    n_names <- length(property_names)
    if (n_names > n_prop)
      property_names <- property_names[seq_len(n_prop)]
    else if (n_names < n_prop)
      property_names <- c(property_names, property[(n_names + 1):n_prop])
  }

  # Resolve numeric list property names
  numeric_list_properties <- as.character(numeric_list_properties)
  if (length(numeric_list_properties) > 0) {
    if (is.null(numeric_list_property_names))
      numeric_list_property_names <- numeric_list_properties
    n_nlp  <- length(numeric_list_properties)
    n_nlpn <- length(numeric_list_property_names)
    if (n_nlpn < n_nlp)
      numeric_list_property_names <- c(numeric_list_property_names,
                                       numeric_list_properties[(n_nlpn + 1):n_nlp])
    if (n_nlpn > n_nlp)
      numeric_list_property_names <- numeric_list_property_names[seq_len(n_nlp)]
  }

  # Validate props requirements
  if (!is.null(property) && length(property) > 0 && !grepl("(^|\\|)claims(\\||$)", entity_props)) {
    stop("property=... requires entity_props to include 'claims'.")
  }
  if (!is.null(numeric_list_properties) && length(numeric_list_properties) > 0 && !grepl("(^|\\|)claims(\\||$)", entity_props)) {
    stop("numeric_list_properties requires entity_props to include 'claims'.")
  }

  # Determine property ID
  property_id <- switch(object_type,
    instance      = "P31",
    subclass      = "P279",
    position_held = "P39"
  )
  type_label <- switch(object_type,
    instance      = "instances",
    subclass      = "subclasses",
    position_held = "position holders"
  )

  # Step 1: re-run SPARQL to get the complete QID list
  message("Re-running SPARQL query for ", class_qid, "...")
  if (verbose) {
    sparql_query <- .build_sparql_query(class_qid, country, property_id, limit)
    message("SPARQL query:\n", sparql_query)
  }
  all_qids <- .sparql_get_qids(class_qid, country, limit, property_id)

  if (length(all_qids) == 0) {
    message("No ", type_label, " found for ", class_qid)
    return(partial_result)
  }

  already_done <- partial_result$qid
  remaining    <- setdiff(all_qids, already_done)

  message(length(already_done), " already retrieved, ",
          length(remaining),    " remaining out of ",
          length(all_qids),     " total.")

  if (length(remaining) == 0) {
    message("Nothing left to fetch -- returning partial_result as-is.")
    return(partial_result |> simplify_list_columns())
  }

  # Step 2: fetch remaining QIDs in batches
  message("Fetching remaining ", length(remaining), " items in batches of ",
          batch_size, "...")
  new_items <- .fetch_qids_in_batches(
    remaining, property, property_names, languages, batch_size, batch_delay,
    numeric_list_properties, numeric_list_property_names,
    entity_props = entity_props,
    object_type = object_type,
    verbose = verbose
  )

  # Simplify each half before binding so column types match
  new_df <- bind_rows(new_items) |> simplify_list_columns()

  combined <- bind_rows(partial_result, new_df) |>
    distinct(qid, .keep_all = TRUE)

  message("Resume complete. Total items: ", nrow(combined))
  combined
}

# ---- simplify_list_columns --------------------------------------------------

#' Simplify Single-Value List Columns in a Data Frame
#'
#' @title Simplify Single-Value List Columns in a Data Frame
#' @description Converts list columns whose elements all have length 0 or 1 into
#'   plain character vectors while leaving multi-valued list columns unchanged.
#'
#' @param df A data frame or tibble.
#'
#' @return The input data frame with qualifying list columns converted to
#'   character vectors.
#'
#' @examples
#' \dontrun{
#' departments <- tibble::tribble(
#' ~qid,             ~label_en, ~cod.dep,
#' "Q233169",     "Beni Department",     "08",
#' "Q233917", "Cochabamba Department",     "03",
#' "Q233933",   "Tarija Department",     "06",
#' "Q235106", "Santa Cruz Department",     "07",
#' "Q235110", "Chuquisaca Department",     "01",
#' "Q235362",    "Pando Department",     "09",
#' "Q238079",   "Potosí Department",     "05",
#' "Q232784",    "La Paz Department",     "02",
#' "Q844510",             "Litoral",       NA,
#' "Q1061368",    "Oruro Department",     "04"
#' )
#' departments_wd <- departments |>
#'   add_wikidata_property("P2131", name = "area_km2")
#' simplify_list_columns(departments_wd)
#' }
#'
#' @export
simplify_list_columns <- function(df) {
  df |>
    mutate(across(
      where(~ is.list(.) && all(map_int(., length) <= 1)),
      ~ map_chr(., ~ if (length(.) == 0) NA_character_ else as.character(.[[1]]))
    ))
}
