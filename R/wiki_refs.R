# wiki_refs.R
# Extract bibliographic references from Wikipedia article wikitext.
# Parses {{Cite book}}, {{Cite journal}}, {{Cite web}}, and related templates
# into a tidy reference tibble.
#
# Exported: extract_refs_from_wikitext
# Internal: find_template_end, extract_templates, parse_template_params,
#           extract_all_citations, extract_bare_refs, clean_wiki,
#           template_to_itemtype, .citation_itemtype, extract_authors,
#           template_to_ref

# Null coalescing: return x if non-NULL, else y
`%||%` <- function(x, y) if (!is.null(x)) x else y

# Citation template names recognised by this parser
.cite_patterns <- c(
  "cite book", "cite journal", "cite web", "cite news",
  "cite encyclopedia", "cite odnb", "cite magazine", "cite thesis",
  "cite conference", "cite report", "cite press release",
  "cite av media", "cite podcast", "cite speech",
  "Citation", "Cite EB1911", "harvc"
)

# Find the closing }} for a template, tracking brace depth.
# Returns the position immediately after the closing }}, or NA if unmatched.
find_template_end <- function(text, start) {
  n     <- nchar(text)
  depth <- 0L
  i     <- start
  chars <- strsplit(substr(text, start, n), "", fixed = TRUE)[[1]]  # scan once
  j <- 1L
  len <- length(chars)
  while (j <= len) {
    if (chars[j] == "{" && j < len && chars[j + 1] == "{") { depth <- depth + 1L; j <- j + 2L }
    else if (chars[j] == "}" && j < len && chars[j + 1] == "}") {
      depth <- depth - 1L
      if (depth == 0L) return(start + j)
      j <- j + 2L
    } else j <- j + 1L
  }
  NA_integer_
}

# Extract all top-level templates matching `pattern` from `text`.
# Scan `text` once and extract all top-level templates whose opening
# tag matches `pattern`. Avoids re-scanning from every candidate start.
extract_templates <- function(text,
                              pattern = "\\{\\{\\s*[Cc]ite\\s") {
  n <- nchar(text)
  templates <- character(0)
  i <- 1L

  while (i <= n) {
    ch2 <- substr(text, i, i + 1L)
    if (ch2 == "{{") {
      # Only pay the regex cost once we're at a "{{" — not per character.
      remainder <- substr(text, i, min(i + 60L, n))  # small lookahead window
      is_match  <- grepl(pattern, remainder, perl = TRUE, ignore.case = TRUE) &&
        regexpr(pattern, remainder, perl = TRUE, ignore.case = TRUE) == 1L

      end_pos <- find_template_end(text, i)
      if (is.na(end_pos)) { i <- i + 2L; next }

      if (is_match) {
        templates <- c(templates, substr(text, i, end_pos))
        i <- end_pos + 1L  # skip past the matched template (avoids double-counting its interior)
      } else {
        i <- i + 2L  # advance past {{ and continue scanning inside the non-matching template
      }
    } else {
      i <- i + 1L
    }
  }
  templates
}

# Parse a wikitext template string into a named list.
# The template name is stored as .template (lowercased).
parse_template_params <- function(template_str) {
  inner <- sub("^\\{\\{\\s*", "", template_str)
  inner <- sub("\\s*\\}\\}$", "", inner)

  # Split on every '|' first (cheap, vectorized), then re-merge pieces
  # that were incorrectly split inside {{...}} or [[...]].
  raw_parts <- strsplit(inner, "|", fixed = TRUE)[[1]]

  parts   <- character(0)
  buffer  <- character(0)
  depth_b <- 0L  # brace depth
  depth_k <- 0L  # bracket depth

  flush <- function() paste(buffer, collapse = "|")

  for (p in raw_parts) {
    depth_b <- depth_b + lengths(regmatches(p, gregexpr("\\{\\{", p))) -
      lengths(regmatches(p, gregexpr("\\}\\}", p)))
    depth_k <- depth_k + lengths(regmatches(p, gregexpr("\\[\\[", p))) -
      lengths(regmatches(p, gregexpr("\\]\\]", p)))
    buffer <- c(buffer, p)
    if (depth_b <= 0L && depth_k <= 0L) {
      parts  <- c(parts, flush())
      buffer <- character(0)
      depth_b <- 0L
      depth_k <- 0L
    }
  }
  if (length(buffer) > 0) parts <- c(parts, flush())

  result      <- list(.template = tolower(trimws(parts[1])))
  unnamed_idx <- 1L
  for (p in parts[-1]) {
    p <- trimws(p)
    if (p == "") next
    eq_pos <- regexpr("=", p, fixed = TRUE)
    if (eq_pos > 0) {
      key <- trimws(substr(p, 1, eq_pos - 1))
      val <- trimws(substr(p, eq_pos + 1, nchar(p)))
      result[[tolower(key)]] <- val
    } else {
      result[[paste0(".unnamed_", unnamed_idx)]] <- p
      unnamed_idx <- unnamed_idx + 1L
    }
  }
  result
}

# Extract all recognised citation templates from wikitext.
extract_all_citations <- function(wikitext) {
  pattern <- paste0(
    "\\{\\{\\s*(",
    paste(gsub(" ", "\\\\s+", .cite_patterns), collapse = "|"),
    ")\\s*\\|"
  )
  extract_templates(wikitext, pattern)
}

# Extract <ref>...</ref> blocks that contain no citation template.
extract_bare_refs <- function(wikitext) {
  refs <- stringr::str_match_all(
    wikitext,
    stringr::regex("<ref[^>]*>(.*?)</ref>", dotall = TRUE)
  )[[1]]
  if (nrow(refs) == 0) return(character(0))
  contents <- refs[, 2]
  is_bare <- !stringr::str_detect(
    contents,
    stringr::regex("\\{\\{\\s*(cite\\s|citation\\s*\\|)", ignore_case = TRUE)
  )
  contents[is_bare & nzchar(trimws(contents))]
}

# Strip wikitext markup from a string: wikilinks, italic marks, templates.
clean_wiki <- function(x) {
  if (is.null(x) || !nzchar(trimws(x))) return(NA_character_)

  # Fast path: nothing to clean if there's no wiki markup at all.
  if (!grepl("\\{\\{|\\[\\[|''", x)) return(trimws(x))

  x <- stringr::str_replace_all(x, "\\{\\{!\\}\\}", "|")
  x <- stringr::str_replace_all(x, "\\{\\{=\\}\\}", "=")
  x <- stringr::str_replace_all(
    x, "\\{\\{[^|{}]+\\|[^|{}]+\\|([^|{}]+)(?:\\|[^{}]*)?\\}\\}", "\\1")
  x <- stringr::str_replace_all(
    x, "\\{\\{[^|{}]+\\|([^|{}]+)\\}\\}", "\\1")
  x <- stringr::str_replace_all(x, "\\{\\{[^{}]*\\}\\}", "")
  x <- stringr::str_replace_all(x, "\\[\\[([^\\]|]+\\|)?([^\\]]+)\\]\\]", "\\2")
  x <- stringr::str_replace_all(x, "''", "")
  trimws(x)
}

# Infer Zotero item type for the generic {{Citation}} template.
.citation_itemtype <- function(params) {
  if (is.null(params)) return("book")
  has <- function(k) !is.null(params[[k]])
  if      (has("chapter") || has("chapter-url")) "bookSection"
  else if (has("journal") || has("periodical"))  "journalArticle"
  else if (has("newspaper"))                     "newspaperArticle"
  else if (has("magazine"))                      "magazineArticle"
  else if (has("encyclopedia"))                  "encyclopediaArticle"
  else                                           "book"
}

# Map a citation template name to a Zotero item type string.
template_to_itemtype <- function(tpl_name, params = NULL) {
  tpl <- tolower(trimws(tpl_name))
  dplyr::case_when(
    stringr::str_detect(tpl, "^(cite )?book$")  ~ "book",
    stringr::str_detect(tpl, "harvc")            ~ "bookSection",
    stringr::str_detect(tpl, "journal")          ~ "journalArticle",
    stringr::str_detect(tpl, "web")              ~ "webpage",
    stringr::str_detect(tpl, "news")             ~ "newspaperArticle",
    stringr::str_detect(tpl, "encyclopedia|odnb|eb1911") ~ "encyclopediaArticle",
    stringr::str_detect(tpl, "magazine")         ~ "magazineArticle",
    stringr::str_detect(tpl, "thesis")           ~ "thesis",
    stringr::str_detect(tpl, "conference")       ~ "conferencePaper",
    stringr::str_detect(tpl, "report")           ~ "report",
    stringr::str_detect(tpl, "press release")    ~ "newspaperArticle",
    stringr::str_detect(tpl, "av media")         ~ "videoRecording",
    stringr::str_detect(tpl, "^citation$")       ~ .citation_itemtype(params),
    TRUE                                         ~ "document"
  )
}

# Extract author/editor/translator metadata from parsed template parameters.
extract_authors <- function(params) {
  rows <- list()  # accumulate here; bind_rows once at the end

  add_row <- function(creator_type, last, first) {
    rows[[length(rows) + 1]] <<- tibble::tibble(
      creatorType = creator_type, lastName = last, firstName = first
    )
  }

  for (role_prefix in c("", "editor", "translator")) {
    creator_type <- if (role_prefix == "") "author" else role_prefix
    param_last  <- if (role_prefix == "") "last"  else paste0(role_prefix, "-last")
    param_first <- if (role_prefix == "") "first" else paste0(role_prefix, "-first")

    for (i in c("", as.character(1:10))) {
      lkey <- paste0(param_last,  i)
      fkey <- paste0(param_first, i)
      last_val  <- params[[lkey]]
      first_val <- params[[fkey]] %||% ""

      if (!is.null(last_val) && nzchar(last_val)) {
        add_row(creator_type,
                clean_wiki(last_val)  %||% "",
                clean_wiki(first_val) %||% "")
      }
    }

    author_key <- if (role_prefix == "") "author" else role_prefix
    no_last <- is.null(params[["last"]]) && is.null(params[["last1"]])
    if (no_last && !is.null(params[[author_key]]) &&
        (length(rows) == 0 || creator_type != "author")) {
      val <- clean_wiki(params[[author_key]]) %||% params[[author_key]]
      if (!is.na(val) && stringr::str_detect(val, ",")) {
        parts <- stringr::str_split(val, ",\\s*", n = 2)[[1]]
        add_row(creator_type, parts[1], parts[2] %||% "")
      } else {
        add_row(creator_type, val, "")
      }
    }
  }

  if (!is.null(params[["others"]]) && nzchar(params[["others"]])) {
    add_row("contributor", params[["others"]], "")
  }

  if (length(rows) == 0) {
    return(tibble::tibble(creatorType = "author", lastName = "", firstName = ""))
  }
  dplyr::bind_rows(rows)
}

# Convert a parsed template parameter list to a one-row reference tibble.
template_to_ref <- function(params) {
  item_type <- template_to_itemtype(params$.template, params)
  authors   <- extract_authors(params)

  extract_year <- function(p) {
    yr <- p[["year"]] %||% p[["date"]]
    if (is.null(yr)) return(NA_character_)
    m <- stringr::str_extract(yr, "\\d{4}")
    if (!is.na(m)) m else yr
  }

  na_coalesce <- function(...) {
    for (a in list(...)) if (!is.na(a)) return(a)
    NA_character_
  }

  tpl_lower <- tolower(trimws(params$.template))

  if (stringr::str_detect(tpl_lower, "eb1911")) {
    title      <- clean_wiki(params[["wstitle"]]) %||% NA_character_
    chapter    <- NA_character_
    book_title <- "Encyclop\u00e6dia Britannica (11th ed.)"
  } else {
    title <- na_coalesce(clean_wiki(params[["title"]]),
                         clean_wiki(params[["script-title"]]))
    if (!is.na(title)) title <- stringr::str_remove(title, "^[a-z]{2}:")

    trans_title <- clean_wiki(params[["trans-title"]])
    if (!is.na(trans_title) && !is.na(title)) {
      title <- paste0(title, " [", trans_title, "]")
    }

    chapter <- na_coalesce(clean_wiki(params[["chapter"]]),
                           clean_wiki(params[["script-chapter"]]))
    if (!is.na(chapter)) chapter <- stringr::str_remove(chapter, "^[a-z]{2}:")

    if (item_type == "bookSection" && !is.na(chapter)) {
      book_title <- title
      title      <- chapter
      chapter    <- NA_character_
    } else if (item_type == "bookSection" && is.na(chapter) && is.na(title)) {
      book_title <- NA_character_
    } else {
      book_title <- if (item_type == "bookSection") {
        clean_wiki(params[["in"]]) %||% NA_character_
      } else {
        NA_character_
      }
    }
  }

  tibble::tibble(
    itemType         = item_type,
    title            = title %||% NA_character_,
    creators         = list(authors),
    date             = params[["date"]]      %||% params[["year"]]    %||% NA_character_,
    year             = extract_year(params),
    publisher        = clean_wiki(params[["publisher"]])              %||% NA_character_,
    place            = clean_wiki(params[["location"]])               %||% NA_character_,
    publicationTitle = clean_wiki(
      params[["journal"]] %||% params[["website"]] %||%
      params[["work"]]    %||% params[["newspaper"]]
    )                                                                 %||% NA_character_,
    volume           = params[["volume"]]                             %||% NA_character_,
    issue            = params[["issue"]]                              %||% NA_character_,
    pages            = params[["pages"]] %||% params[["page"]] %||%
                         params[["at"]]                               %||% NA_character_,
    ISBN             = params[["isbn"]]                               %||% NA_character_,
    ISSN             = params[["issn"]]                               %||% NA_character_,
    DOI              = params[["doi"]]                                %||% NA_character_,
    url              = params[["url"]] %||% params[["chapter-url"]]  %||% NA_character_,
    language         = params[["language"]]                           %||% NA_character_,
    edition          = params[["edition"]]                            %||% NA_character_,
    series           = clean_wiki(params[["series"]])                 %||% NA_character_,
    accessDate       = params[["access-date"]]                        %||% NA_character_,
    bookTitle        = book_title                                     %||% NA_character_,
    chapter          = chapter                                        %||% NA_character_,
    .template_name   = params$.template,
    .raw_template    = NA_character_
  )
}

#' Extract Citation References from Wikitext
#'
#' Parses all `{{Cite book}}`, `{{Cite journal}}`, `{{Cite web}}`, and related
#' Wikipedia citation templates from raw wikitext into a tidy reference tibble.
#' Also captures bare `<ref>` notes that contain no citation template.
#'
#' Recognised template families: Cite book, Cite journal, Cite web, Cite news,
#' Cite encyclopedia, Cite magazine, Cite thesis, Cite conference, Cite report,
#' Cite press release, Cite av media, Cite podcast, Cite speech, Citation,
#' Cite EB1911, and harvc.
#'
#' @param wikitext Character. Raw wikitext string as returned by
#'   [get_wikitext_by_name()] or [cache_wikitext()].
#' @return A tibble with one row per citation found and columns:
#'   `itemType`, `title`, `creators` (list-column of tibbles), `date`, `year`,
#'   `publisher`, `place`, `publicationTitle`, `volume`, `issue`, `pages`,
#'   `ISBN`, `ISSN`, `DOI`, `url`, `language`, `edition`, `series`,
#'   `accessDate`, `bookTitle`, `chapter`, `first_author`, `.template_name`,
#'   `.raw_template`. Issues a warning and returns an empty tibble if no
#'   citation templates are found.
#'
#' @examples
#' \dontrun{
#' wt   <- get_wikitext_by_name("Meiō incident")
#' refs <- extract_refs_from_wikitext(wt)
#' dplyr::count(refs, itemType, sort = TRUE)
#' }
#'
#' @seealso [get_wikitext_by_name()], [cache_wikitext()]
#' @export
extract_refs_from_wikitext <- function(wikitext) {
  cite_strings <- extract_all_citations(wikitext)

  if (length(cite_strings) == 0) {
    warning("No citation templates found in wikitext.")
    return(tibble::tibble())
  }

  parsed <- purrr::map(cite_strings, parse_template_params)

  refs <- purrr::map2(parsed, cite_strings, function(params, raw) {
    ref <- template_to_ref(params)
    ref$.raw_template <- raw
    ref
  }) |> dplyr::bind_rows()

  bare <- extract_bare_refs(wikitext)
  if (length(bare) > 0) {
    bare_df <- tibble::tibble(
      itemType         = "document",
      title            = purrr::map_chr(bare, clean_wiki),
      creators         = purrr::map(bare, ~ tibble::tibble(
        creatorType = "author", lastName = "", firstName = ""
      )),
      date = NA_character_, year = NA_character_, publisher = NA_character_,
      place = NA_character_, publicationTitle = NA_character_,
      volume = NA_character_, issue = NA_character_, pages = NA_character_,
      ISBN = NA_character_, ISSN = NA_character_, DOI = NA_character_,
      url = NA_character_, language = NA_character_, edition = NA_character_,
      series = NA_character_, accessDate = NA_character_,
      bookTitle = NA_character_, chapter = NA_character_,
      .template_name = "bare_ref", .raw_template = bare
    )
    refs <- dplyr::bind_rows(refs, bare_df)
  }

  dplyr::mutate(refs,
    first_author = purrr::map_chr(creators, function(cr) {
      if (nrow(cr) == 0) return(NA_character_)
      last  <- cr$lastName[1]  %||% ""
      first <- cr$firstName[1] %||% ""
      if (!nzchar(last) && !nzchar(first)) return(NA_character_)
      if (nzchar(first)) paste0(last, ", ", first) else last
    }),
    .before = creators
  )
}
