# Function Inventory: wikitools vs wiki-graph

## Overview

This document compares function definitions across the two projects.

## wikitools Project

**File:** `docs/wikitools-functions.md`

- **Total Functions:** 35
- **Exported Functions:** 28
- **Internal Functions:** 7
- **Focus:** Core Wikipedia and Wikidata tools for general use

### Main Categories
1. Wikipedia text fetching and caching
2. Wikitext content parsing (infoboxes, citations, census years)
3. Wikipedia category management
4. Wikidata property retrieval
5. Wikidata instance/class queries
6. QuickStatements command generation
7. String equivalence/matching with accent and case handling

### Key Files
- `R/wikipedia-tools.R` - Main Wikipedia utilities (17 functions)
- `R/get_wikidata_instances.R` - Wikidata class/instance retrieval (13 functions)
- `R/create_quick_statement.R` - QuickStatements generation (4 functions)
- `R/str-equivalent.R` - String matching (4 functions)
- `R/add-wikipedia-matches.R` - Wikipedia search (1 function)

---

## wiki-graph Project

**File:** `docs/wiki-graph-unique-functions.md`

- **Total Unique Functions (with Wikipedia/Wikidata):** 141+
- **Focus:** Project-specific data processing and Wikipedia article generation

### Main Categories
1. **Data Processing** (22 functions) - Census data, INE codes, facility data cleaning
2. **Wikidata/Semantic Web** (8 functions) - Frequency analysis, presence tracking
3. **Wikipedia Content** (6 functions) - Plain text extraction, edit tracking
4. **Edit Tracking** (5 functions) - Wikiblame integration, sentence history
5. **Reference Management** (24 functions) - Zotero integration, reference parsing
6. **Wikitext Generation** (17 functions) - Article templates, infoboxes
7. **Commons/File Management** (13 functions) - File uploads, Structured Data
8. **Geographic/Maps** (5 functions) - Locator map generation
9. **Data Analysis** (13 functions) - Presence analysis, name matching
10. **Visualization** (14 functions) - Maps, tables, formatting

---

## Comparison

### Functions in BOTH Projects

These functions exist in both wikitools and wiki-graph:
- `add_quick_statement_column` - Used in add_ine_codes_to_wikidata.R
- `add_quick_statement_column_q` - Used in cpv2024-population-quickstatements.qmd
- `add_wikidata_property` - Used in get_wikidata_instances_v1.R
- `create_quick_statement` - Core wikidata editing
- `extract_clean_fragments` - Text extraction from Wikipedia
- `get_wikidata_instances` - Wikidata instance queries
- `resume_get_wikidata_instances` - Resume interrupted queries
- `simplify_list_columns` - Data frame manipulation
- `add_wikipedia_matches` - Wikipedia search (referenced in workflows)

### Functions ONLY in wikitools

These are general-purpose utilities:
- `get_wikitext_by_name()`, `get_wikitext_by_revid()`, `get_wikitext_from_url()`
- `extract_infobox()`, `clean_infobox_value()`
- `count_citations()`, `count_refs()`, `extract_census_years()`
- `cache_wikitext()`
- `get_wp_category_members()`, `get_wp_subcategories()`, `get_wp_category_pages()`
- `get_page_info_batch()`
- `as_wikitable()`
- `add_wikidata_property()`
- `str_equivalent()`, `equivalent_which()`, `equivalent_match()`, `str_equivalent_list()`

### Functions ONLY in wiki-graph

These are mostly project-specific:
- **High-value candidates for wikitools migration:**
  - `get_plain_text()`, `wikitext_to_plain()` - Wikipedia text extraction
  - `get_wikidata_frequencies()` - Property frequency analysis
  - `wiki_refs_pipeline()` - Reference extraction pipeline
  - `track_wikipedia_sentences()`, `find_sentence_insertion()` - Edit tracking
  - `wikidata_instance_wikipedia_presence()` - Presence analysis
  - `extract_refs_from_wikitext()` - Reference extraction
  
- **Specialized/domain-specific:**
  - Census/INE code functions (add_ine_code_* family)
  - Zotero integration (multiple ref_to_* functions)
  - Bolivia-specific generators (compose_* functions)
  - Commons upload functions
  - Locator map generation

---

## Recommendations

### For Code Reuse
Consider migrating these wiki-graph functions to wikitools if they're used across multiple projects:
1. `get_plain_text()` - General Wikipedia text extraction
2. `extract_refs_from_wikitext()` - Reference extraction
3. `wikidata_instance_wikipedia_presence()` - Presence checking
4. `get_wikidata_frequencies()` - Frequency analysis
5. `track_wikipedia_sentences()` - Edit tracking

### For Dependency Management
Some wiki-graph files import from wikitools:
- `add_ine_codes_to_wikidata.R` uses `add_quick_statement_column()`
- `get_wikidata_instances_v1.R` is a local version of functions now in wikitools
- Several Quarto documents depend on wikitools for Wikidata/Wikipedia access

### Documentation Maintenance
- Keep wikitools-functions.md updated as new exported functions are added
- Review wiki-graph functions annually for candidates to promote to wikitools
- Document function dependencies between projects
