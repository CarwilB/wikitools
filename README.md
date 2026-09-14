# wikitools

wikitools provides R functions for retrieving, parsing, and matching Wikipedia and Wikidata content. It covers searching both platforms, navigating Wikipedia categories and Wikidata class hierarchies, fetching and parsing article text, tables, and revision histories, and generating QuickStatements commands for editing Wikidata.

## Installation

``` r
# install.packages("remotes")
remotes::install_github("CarwilB/wikitools")
```

## Searching Wikipedia and Wikidata

`add_wikipedia_matches()` and `add_wikidata_matches()` search each value in a name column against Wikipedia article titles or Wikidata labels and aliases, and append match metadata to the data frame: whether anything was found, whether the top hit is an exact text match, the matched title or QID, URL, and description. Both accept a vector of language codes, searching each language in turn and appending one set of columns per language.

The top search hit is not always the intended article — an album title may also name a film, or a name may be shared by two people. `find_wikipedia_matches()` returns the top `n` candidates (six by default) for each string as a ranked, long-format tibble, and `choose_wikipedia_matches()` presents those candidates in an interactive menu, with each article's short description shown alongside the title. Results from the interactive menu can be saved and reloaded so that subsequent runs of a script do not require re-prompting the user.

## Navigating Wikipedia by categories

`get_wp_category_members()` returns the pages and/or subcategories of a Wikipedia category, while limiting API calls so as to limit demand on the API server. `get_wp_category_pages()` and `get_wp_subcategories()` are convenience wrappers that restrict the result to articles or subcategories, respectively. Results are returned as tibbles of page IDs, namespaces, and titles. `get_page_info_batch()` fetches metadata, while batching API requests.

## Navigating Wikidata by instances and subclasses

`get_wikidata_instances()` retrieves, via SPARQL, all items that are an instance (P31) or subclass (P279) of a given class, or all persons on Wikidata that have held a given position (P39), with an optional country filter. Items are fetched from the Wikidata API in batches of 50, with labels and descriptions in the requested languages, optional additional properties, and multi-valued quantity properties (such as population figures recorded across several years) unpacked into value, year, and reference columns. Long-running queries record their progress and can be resumed with `resume_get_wikidata_instances()`. `get_wikidata_items()` performs the same retrieval and enrichment for a predetermined list of QIDs, without the SPARQL step.

Wikidata items record sitelinks to each corresponding Wikipedia page. Using this information, the package also has functions for checking Wikipedia coverage: `wikidata_instance_wikipedia_presence()` builds a matrix indicating which Wikipedia language editions have an article for each instance, and `unpack_wikipedia_article_info()` reshapes the resulting sitelink list-column into per-language presence, title, and URL columns. When this search is interrupted, it can be resumed with `resume_wikidata_instance_wikipedia_presence().`

## Retrieving and analyzing Wikipedia pages

Raw wikitext can be fetched by article name (`get_wikitext_by_name()`), by revision ID (`get_wikitext_by_revid()`), or from a URL (`get_wikitext_from_url()`), including `?oldid=` revision links, with the language inferred from the subdomain. `cache_wikitext()` downloads and stores wikitext locally for reuse, and `get_plain_text()` converts Wikitext into plain text, stripping away any markup.

A set of parsing functions then operates on wikitext without requiring further network access. `extract_infobox()` parses the first infobox (recognizing English `Infobox`, Spanish `Ficha de`, and Portuguese `Info/` conventions) into a named list of fields, using brace-depth matching to handle nested templates, and `clean_infobox_value()` strips markup from an individual field (flag templates, `{{convert}}` units, `<ref>` tags, wikilinks) to produce plain text. `extract_clean_fragments()` splits an article into sentence-like plain-text fragments, and `wikitext_to_plain()` converts wikitext to plain text via Pandoc. For citation analysis, `count_citations()` and `count_refs()` count citation templates and `<ref>` tags, and `extract_refs_from_wikitext()` parses sixteen citation template families (Cite book, Cite journal, Cite web, and related templates) into a tidy tibble of authors, titles, dates, publishers, and identifiers.

A related set of functions traces when content was added to an article. `get_revision_history_map()` fetches an article's full revision history, paginating automatically over articles with thousands of revisions. `find_sentence_insertion()` performs a binary search over that history to identify the revision in which a given sentence first appeared, requiring at most about 10 API calls for an article with 1,000 revisions. `track_wikipedia_sentences()` applies this search to a list of sentences, recording who added each one and when.

## Retrieving Wikipedia tables

`get_wikitable()` retrieves a rendered `wikitable` from a Wikipedia article, selecting the table by matching a substring against its caption (and listing available captions if no match is found). The article link behind each row's header cell can also be extracted into an adjacent `_link` column. `clean_column_headers()` converts raw header text into snake_case variable names, preserving acronyms such as `UK`, and `link_to_article_name()` converts a link URL back into a plain article title.

## Turning data into wikitext tables

`as_wikitable()` performs the reverse conversion, formatting an R data frame as MediaWiki wikitable markup, with columns as headers, rows as table rows, and `NA` values rendered as empty cells. An optional caption and CSS class can be supplied.

## Editing Wikidata via QuickStatements

`create_quick_statement()` generates a single QuickStatements V1 command for strings, monolingual text, labels, descriptions, aliases, items, times, quantities, or coordinates, with optional qualifiers, references, and retrieved dates. `add_quick_statement_column()`, `add_quick_statement_column_q()` (with qualifiers), and `remove_quick_statement_column()` generate the corresponding commands for every row of a data frame. `add_wikidata_property()` performs the reverse operation, reading a single-valued property from Wikidata and appending it as a new column to a data frame that contains a `qid` column.

## Other utilities

`str_equivalent()` compares two strings after normalizing whitespace, accents, and case, so that, for example, `"  Café"` and `"cafe"` are considered equivalent. `equivalent_which()`, `equivalent_match()`, and `str_equivalent_list()` apply this comparison to find matching positions, matching values, or any-match flags within a vector. `simplify_list_columns()` unlists single-value list columns in a data frame into plain vectors.
