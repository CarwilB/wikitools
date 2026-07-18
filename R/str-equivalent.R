#' Normalize and Compare Two Strings
#'
#' Compares two character vectors for equivalence after applying a standard set
#' of normalizations: trimming leading/trailing whitespace, replacing
#' non-breaking spaces (`\\u00a0`) with regular spaces, removing accents via
#' Latin-ASCII transliteration, removing double quotes, and ignoring case.
#'
#' @param x A character vector.
#' @param y A character vector. Must be the same length as `x`, or length 1
#'   (recycled).
#' @return A logical vector the same length as the longer of `x` and `y`.
#'   `TRUE` where the normalized strings are equal. Returns `NA` where either
#'   input is `NA`.
#'
#' @examples
#' str_equivalent("  Café", "cafe")                   # TRUE — accents + whitespace
#' str_equivalent("Hello\u00a0World", "hello world")  # TRUE — non-breaking space
#' str_equivalent('Quote"', "quote")                  # TRUE — double quote removed
#' str_equivalent("SUCRE", "sucre")                   # TRUE — case
#' str_equivalent("Mismatch", "mismatch!")             # FALSE
#'
#' @seealso [equivalent_which()], [equivalent_match()], [str_equivalent_list()]
#' @importFrom stringr str_replace_all str_equal
#' @importFrom stringi stri_trans_general
#' @export
str_equivalent <- function(x, y) {
  x <- trimws(x)
  y <- trimws(y)

  x <- stringr::str_replace_all(x, "\u00a0", " ")
  y <- stringr::str_replace_all(y, "\u00a0", " ")

  x <- stringi::stri_trans_general(x, "Latin-ASCII")
  y <- stringi::stri_trans_general(y, "Latin-ASCII")

  x <- stringr::str_replace_all(x, "\u0022", "")
  y <- stringr::str_replace_all(y, "\u0022", "")

  stringr::str_equal(x, y, ignore_case = TRUE)
}

#' Find Positions of Equivalent Strings in a Vector
#'
#' Returns the indices of elements in `string_list` that are equivalent to
#' `string` under [str_equivalent()] normalization (case, accents, whitespace,
#' non-breaking spaces, double quotes).
#'
#' @param string A character string to search for.
#' @param string_list A character vector to search in.
#' @return An integer vector of matching positions, or `integer(0)` if none
#'   match.
#'
#' @examples
#' equivalent_which("café", c("cafe", "tea", "coffee"))  # 1
#' equivalent_which("hello", c("world", "Hello"))        # 2
#' equivalent_which("nope", c("a", "b", "c"))            # integer(0)
#'
#' @seealso [str_equivalent()], [equivalent_match()], [str_equivalent_list()]
#' @export
equivalent_which <- function(string, string_list) {
  which(str_equivalent(string, string_list))
}

#' Return Equivalent Strings from a Vector
#'
#' Returns all elements of `string_list` that are equivalent to `string` under
#' [str_equivalent()] normalization (case, accents, whitespace, non-breaking
#' spaces, double quotes). Returns `NA` when no match is found.
#'
#' @param string A character string to search for.
#' @param string_list A character vector to search in.
#' @return The matching elements of `string_list` as a character vector, or
#'   `NA` if no equivalent is found. If multiple elements match, all are
#'   returned.
#'
#' @examples
#' equivalent_match("café", c("cafe", "tea", "coffee"))  # "cafe"
#' equivalent_match("hello", c("Hello", "world"))        # "Hello"
#' equivalent_match("bye", c("Hello", "world"))          # NA
#'
#' @seealso [str_equivalent()], [equivalent_which()], [str_equivalent_list()]
#' @export
equivalent_match <- function(string, string_list) {
  if (length(equivalent_which(string, string_list)) == 0)
    return(NA)
  string_list[which(str_equivalent(string, string_list))]
}

#' Check Whether Any String in a Vector Is Equivalent
#'
#' Returns `TRUE` if any element of `string_list` is equivalent to `string`
#' under [str_equivalent()] normalization (case, accents, whitespace,
#' non-breaking spaces, double quotes).
#'
#' @param string A character string to search for.
#' @param string_list A character vector of candidates.
#' @return A single logical value: `TRUE` if any element matches, `FALSE`
#'   otherwise. Returns `NA` if no element matches and `string_list` contains
#'   `NA` values.
#'
#' @examples
#' str_equivalent_list("café", c("cafe", "tea", "coffee"))  # TRUE
#' str_equivalent_list("hello", c("world", "hi"))           # FALSE
#' str_equivalent_list("x", character(0))                   # FALSE
#'
#' @seealso [str_equivalent()], [equivalent_which()], [equivalent_match()]
#' @export
str_equivalent_list <- function(string, string_list) {
  any(sapply(string_list, function(x) str_equivalent(string, x)))
}
