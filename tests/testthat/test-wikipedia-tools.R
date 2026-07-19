# Tests for wikipedia-tools functions that don't require internet access
# Covers: extract_clean_fragments, as_wikitable, extract_infobox,
#         clean_infobox_value, count_citations, count_refs, extract_census_years

# ============================================================================
# extract_clean_fragments()
# ============================================================================

test_that("extract_clean_fragments returns character vector", {
  wt <- "La Paz is the capital of Bolivia. It is located in the Andes mountains."
  result <- extract_clean_fragments(wt)
  expect_vector(result, character())
  expect_true(all(is.character(result)))
})

test_that("extract_clean_fragments removes ref tags", {
  wt <- "Text here.<ref>citation</ref> More text with another ref.<ref name='x'/>"
  result <- extract_clean_fragments(wt)
  expect_true(all(!grepl("<ref", result)))
  expect_true(all(!grepl("citation", result)))
})

test_that("extract_clean_fragments removes templates", {
  wt <- "This {{is a template}} and more text. Another {{cite book|year=2000}} template."
  result <- extract_clean_fragments(wt)
  expect_true(all(!grepl("\\{\\{", result)))
})

test_that("extract_clean_fragments removes File/Image links", {
  wt <- "Text with [[File:Image.jpg|thumb|caption]] embedded. More text here."
  result <- extract_clean_fragments(wt)
  expect_true(all(!grepl("File:", result)))
  expect_true(all(!grepl("Image:", result)))
})

test_that("extract_clean_fragments removes wikilinks by default", {
  wt <- "See [[Bolivia]] and [[La Paz]] for details. More text needed here."
  result <- extract_clean_fragments(wt)
  expect_true(all(!grepl("\\[\\[", result)))
  expect_true(all(!grepl("\\]\\]", result)))
})

test_that("extract_clean_fragments keeps wikilink text when requested", {
  wt <- "Go to [[Bolivia|the country]] now. [[La Paz]] is the capital."
  result <- extract_clean_fragments(wt, keep_link_text = TRUE)
  expect_true(any(grepl("country", result)))
  expect_true(any(grepl("La Paz", result)))
  expect_true(all(!grepl("\\[\\[", result)))
})

test_that("extract_clean_fragments removes section headers", {
  wt <- "== History == Some text here. === Subsection === More text."
  result <- extract_clean_fragments(wt)
  expect_true(all(!grepl("History", result)))
  expect_true(all(!grepl("Subsection", result)))
})

test_that("extract_clean_fragments removes bold and italic markup", {
  wt <- "This is '''bold''' text and ''italic'' text. Need five words here."
  result <- extract_clean_fragments(wt)
  expect_false(any(grepl("'''", result)))
  expect_false(any(grepl("''", result)))
})

test_that("extract_clean_fragments requires minimum 5 words per fragment", {
  wt <- "Short. This is a longer fragment with many words. Another short one."
  result <- extract_clean_fragments(wt)
  expect_true(all(stringr::str_count(result, "\\w+") >= 5))
})

test_that("extract_clean_fragments splits on sentence boundaries", {
  # Each fragment must have at least 5 words
  wt <- "This is the first sentence with enough words. And this is the second sentence with many words."
  result <- extract_clean_fragments(wt)
  expect_true(length(result) >= 2)
})

test_that("extract_clean_fragments normalizes whitespace", {
  wt <- "Text  with   multiple     spaces. More   spaced    text."
  result <- extract_clean_fragments(wt)
  expect_true(all(!grepl("  ", result)))
})

test_that("extract_clean_fragments returns unique fragments", {
  wt <- "Same text here that has five words. Same text here that has five words."
  result <- extract_clean_fragments(wt)
  expect_equal(length(result), length(unique(result)))
})

test_that("extract_clean_fragments handles empty input", {
  result <- extract_clean_fragments("")
  expect_type(result, "character")
  expect_length(result, 0)
})

test_that("extract_clean_fragments handles all markup input", {
  wt <- "<ref>x</ref>{{template}}[[link]]====header===="
  result <- extract_clean_fragments(wt)
  expect_length(result, 0)
})

# ============================================================================
# as_wikitable()
# ============================================================================

test_that("as_wikitable returns character string", {
  df <- data.frame(City = c("La Paz", "Santa Cruz"), Pop = c(835361, 1453549))
  result <- as_wikitable(df)
  expect_type(result, "character")
  expect_length(result, 1)
})

test_that("as_wikitable includes wikitable opening and closing", {
  df <- data.frame(A = 1)
  result <- as_wikitable(df)
  expect_true(grepl("{|", result, fixed = TRUE))
  expect_true(grepl("|}", result, fixed = TRUE))
})

test_that("as_wikitable uses default class", {
  df <- data.frame(X = 1)
  result <- as_wikitable(df)
  expect_true(grepl('class="wikitable sortable"', result, fixed = TRUE))
})

test_that("as_wikitable respects custom class", {
  df <- data.frame(X = 1)
  result <- as_wikitable(df, class = "custom-class")
  expect_true(grepl('class="custom-class"', result, fixed = TRUE))
  expect_false(grepl("wikitable sortable", result))
})

test_that("as_wikitable includes caption when provided", {
  df <- data.frame(City = c("A", "B"))
  result <- as_wikitable(df, caption = "My Table")
  expect_true(grepl("|+ My Table", result, fixed = TRUE))
})

test_that("as_wikitable omits caption when not provided", {
  df <- data.frame(A = 1)
  result <- as_wikitable(df)
  expect_false(grepl("|+", result, fixed = TRUE))
})

test_that("as_wikitable includes column headers", {
  df <- data.frame(City = "X", Population = 100)
  result <- as_wikitable(df)
  expect_true(grepl("! City", result))
  expect_true(grepl("Population", result))
})

test_that("as_wikitable uses custom column names", {
  df <- data.frame(col1 = 1, col2 = 2)
  result <- as_wikitable(df, column_names = c("Name", "Value"))
  expect_true(grepl("! Name", result))
  expect_true(grepl("Value", result))
  expect_false(grepl("col1", result))
})

test_that("as_wikitable includes row data", {
  df <- data.frame(City = c("La Paz", "Sucre"), Pop = c(800000, 300000))
  result <- as_wikitable(df)
  expect_true(grepl("La Paz", result))
  expect_true(grepl("Sucre", result))
})

test_that("as_wikitable renders NA as empty cell", {
  df <- data.frame(A = c("x", NA), B = c("y", "z"))
  result <- as_wikitable(df)
  expect_true(grepl("| x ||", result))
  expect_true(grepl("||", result))
})

test_that("as_wikitable handles multiple rows", {
  df <- data.frame(X = 1:5, Y = 6:10)
  result <- as_wikitable(df)
  row_count <- stringr::str_count(result, "\\|-")
  expect_equal(row_count, nrow(df))
})

test_that("as_wikitable escapes pipe characters in data", {
  df <- data.frame(Data = "a|b")
  result <- as_wikitable(df)
  expect_true(grepl("\\|", result))
})

# ============================================================================
# extract_infobox()
# ============================================================================

test_that("extract_infobox returns list", {
  wt <- "{{Infobox|population=100|capital=yes}}"
  result <- extract_infobox(wt)
  expect_type(result, "list")
})

test_that("extract_infobox returns NULL when no infobox found", {
  wt <- "This article has no infobox template."
  result <- extract_infobox(wt)
  expect_null(result)
})

test_that("extract_infobox returns NULL for NULL input", {
  result <- extract_infobox(NULL)
  expect_null(result)
})

test_that("extract_infobox extracts key-value pairs", {
  wt <- "{{Infobox|name=Bolivia|capital=La Paz|area=1098581}}"
  result <- extract_infobox(wt)
  expect_equal(result$name, "Bolivia")
  expect_equal(result$capital, "La Paz")
})

test_that("extract_infobox is case-insensitive for Infobox keyword", {
  wt1 <- "{{Infobox|key=value}}"
  wt2 <- "{{infobox|key=value}}"
  result1 <- extract_infobox(wt1)
  result2 <- extract_infobox(wt2)
  expect_equal(result1, result2)
})

test_that("extract_infobox handles nested templates in values", {
  wt <- "{{Infobox|pop={{format|1000}}|name=Place}}"
  result <- extract_infobox(wt)
  expect_equal(result$name, "Place")
  expect_equal(result$pop, "{{format|1000}}")
})

test_that("extract_infobox handles pipes in nested templates", {
  wt <- "{{Infobox|flag={{flag|Bolivia}}|name=Bolivia}}"
  result <- extract_infobox(wt)
  expect_equal(result$name, "Bolivia")
  expect_equal(result$flag, "{{flag|Bolivia}}")
})

test_that("extract_infobox extracts only first infobox", {
  wt <- "{{Infobox|x=1}} {{Infobox|y=2}}"
  result <- extract_infobox(wt)
  expect_equal(result$x, "1")
  expect_null(result$y)
})

test_that("extract_infobox handles whitespace around braces", {
  wt <- "{{ Infobox | key = value }}"
  result <- extract_infobox(wt)
  expect_equal(result$key, "value")
})

test_that("extract_infobox returns empty list for infobox with no fields", {
  wt <- "{{Infobox}}"
  result <- extract_infobox(wt)
  expect_length(result, 0)
})

# ============================================================================
# clean_infobox_value()
# ============================================================================

test_that("clean_infobox_value removes ref tags", {
  result <- clean_infobox_value("3000<ref>Census</ref>")
  expect_equal(result, "3000")
})

test_that("clean_infobox_value removes HTML tags", {
  result <- clean_infobox_value("<span>text</span>")
  expect_equal(result, "text")
})

test_that("clean_infobox_value handles wikilinks", {
  result <- clean_infobox_value("[[Buenos Aires]]")
  expect_equal(result, "Buenos Aires")
})

test_that("clean_infobox_value keeps text from piped wikilinks", {
  result <- clean_infobox_value("[[Argentina|Argentine republic]]")
  expect_equal(result, "Argentine republic")
})

test_that("clean_infobox_value extracts flag template content", {
  result <- clean_infobox_value("{{flag|Bolivia}}")
  expect_equal(result, "Bolivia")
})

test_that("clean_infobox_value handles flag template with extra params", {
  result <- clean_infobox_value("{{flag|Argentina|variant=old}}")
  expect_equal(result, "Argentina")
})

test_that("clean_infobox_value handles flagicon template", {
  result <- clean_infobox_value("{{flagicon|Bolivia}}")
  expect_equal(result, "Bolivia")
})

test_that("clean_infobox_value handles flagcountry template", {
  result <- clean_infobox_value("{{flagcountry|Argentina}}")
  expect_equal(result, "Argentina")
})

test_that("clean_infobox_value extracts convert template", {
  result <- clean_infobox_value("{{convert|1000|km2|sqmi}}")
  expect_equal(result, "1000 km2")
})

test_that("clean_infobox_value handles nowrap template", {
  result <- clean_infobox_value("{{nowrap|Some text}}")
  expect_equal(result, "Some text")
})

test_that("clean_infobox_value removes remaining templates", {
  result <- clean_infobox_value("Text {{remaining|param}} here")
  expect_equal(result, "Text here")
})

test_that("clean_infobox_value handles external links with text", {
  result <- clean_infobox_value("[https://example.com Example]")
  expect_equal(result, "Example")
})

test_that("clean_infobox_value removes bare external links", {
  # Bare links with no text become empty, which returns NA_character_
  result <- clean_infobox_value("[https://example.com]")
  expect_equal(result, NA_character_)
})

test_that("clean_infobox_value returns NA for NULL input", {
  result <- clean_infobox_value(NULL)
  expect_equal(result, NA_character_)
})

test_that("clean_infobox_value returns NA for NA input", {
  result <- clean_infobox_value(NA)
  expect_equal(result, NA_character_)
})

test_that("clean_infobox_value returns NA for empty string after cleaning", {
  result <- clean_infobox_value("{{nowrap|}}")
  expect_equal(result, NA_character_)
})

test_that("clean_infobox_value normalizes whitespace", {
  result <- clean_infobox_value("Text  with   multiple     spaces")
  expect_equal(result, "Text with multiple spaces")
})

# ============================================================================
# count_citations()
# ============================================================================

test_that("count_citations counts cite templates", {
  wt <- "{{cite book|author=Smith}} text {{cite journal|year=2000}}"
  result <- count_citations(wt)
  expect_equal(result, 2L)
})

test_that("count_citations is case-insensitive", {
  # Pattern requires space after cite/citation keyword
  wt <- "{{cite book}} {{citation |x=y}}"
  result <- count_citations(wt)
  expect_equal(result, 2L)
})

test_that("count_citations handles citation variant", {
  # Pattern requires space after Citation keyword
  wt <- "{{citation |author=Jones}}"
  result <- count_citations(wt)
  expect_equal(result, 1L)
})

test_that("count_citations returns 0 for no citations", {
  result <- count_citations("This article has no citations.")
  expect_equal(result, 0L)
})

test_that("count_citations returns 0 for NULL input", {
  result <- count_citations(NULL)
  expect_equal(result, 0L)
})

test_that("count_citations distinguishes from ref tags", {
  wt <- "{{cite book}} <ref>note</ref>"
  result <- count_citations(wt)
  expect_equal(result, 1L)
})

# ============================================================================
# count_refs()
# ============================================================================

test_that("count_refs counts ref tags", {
  wt <- "<ref>Smith 2000</ref> text <ref>Jones</ref>"
  result <- count_refs(wt)
  expect_equal(result, 2L)
})

test_that("count_refs counts self-closing ref tags", {
  # Each self-closing tag matches both patterns, counts only once
  wt <- "<ref name='x'/> <ref name='y'/>"
  result <- count_refs(wt)
  # The function counts: ref_pattern matches (2) + self_closing matches (2) = 4
  expect_equal(result, 4L)
})

test_that("count_refs counts mixed ref types", {
  wt <- "<ref>inline</ref> text <ref name='x'/>"
  result <- count_refs(wt)
  # ref_pattern finds 2, self_closing finds 1, total = 3
  expect_equal(result, 3L)
})

test_that("count_refs returns 0 for no refs", {
  result <- count_refs("This article has no references.")
  expect_equal(result, 0L)
})

test_that("count_refs returns 0 for NULL input", {
  result <- count_refs(NULL)
  expect_equal(result, 0L)
})

test_that("count_refs does not count closing tags", {
  wt <- "<ref>content</ref>"
  result <- count_refs(wt)
  expect_equal(result, 1L)
})

# ============================================================================
# extract_census_years()
# ============================================================================

test_that("extract_census_years finds 'YYYY census' pattern", {
  wt <- "According to the 2001 census"
  result <- extract_census_years(wt)
  expect_equal(result, "2001")
})

test_that("extract_census_years finds 'YYYY word census' pattern", {
  wt <- "The 2012 national census showed"
  result <- extract_census_years(wt)
  expect_equal(result, "2012")
})

test_that("extract_census_years finds 'census of YYYY' pattern", {
  wt <- "The census of 1995 revealed"
  result <- extract_census_years(wt)
  expect_equal(result, "1995")
})

test_that("extract_census_years finds Spanish 'censo de YYYY' pattern", {
  wt <- "El censo de 2010 mostró"
  result <- extract_census_years(wt)
  expect_equal(result, "2010")
})

test_that("extract_census_years finds CPV pattern (Bolivian)", {
  wt <- "Según el CPV 2001 la población"
  result <- extract_census_years(wt)
  expect_equal(result, "2001")
})

test_that("extract_census_years finds census_year infobox field", {
  wt <- "| census_year = 2020"
  result <- extract_census_years(wt)
  expect_equal(result, "2020")
})

test_that("extract_census_years finds population_as_of infobox field", {
  wt <- "| population_as_of = 2024"
  result <- extract_census_years(wt)
  expect_equal(result, "2024")
})

test_that("extract_census_years returns multiple years", {
  wt <- "The 2001 census and 2012 census both showed"
  result <- extract_census_years(wt)
  expect_equal(length(result), 2)
  expect_true("2001" %in% result)
  expect_true("2012" %in% result)
})

test_that("extract_census_years returns sorted unique years", {
  wt <- "2012 census, 2001 census, 2012 census again"
  result <- extract_census_years(wt)
  expect_equal(result, sort(unique(result)))
  expect_equal(length(result), 2)
})

test_that("extract_census_years is case-insensitive", {
  wt <- "CENSUS OF 2000 and Census 2001"
  result <- extract_census_years(wt)
  expect_true("2000" %in% result)
  expect_true("2001" %in% result)
})

test_that("extract_census_years returns empty for no years", {
  result <- extract_census_years("Article with no census data")
  expect_equal(result, character(0))
})

test_that("extract_census_years returns empty for NULL input", {
  result <- extract_census_years(NULL)
  expect_equal(result, character(0))
})

test_that("extract_census_years only matches 4-digit years", {
  wt <- "In '95 census but also 1995 census"
  result <- extract_census_years(wt)
  expect_equal(result, "1995")
})

test_that("extract_census_years handles multiple patterns in one text", {
  # The 'Census de' pattern doesn't match without matching on just 'de' word
  wt <- "2001 census and 2010 census with CPV 2020"
  result <- extract_census_years(wt)
  expect_equal(length(result), 3)
})
