# Functions in wikitools Project

**Total: 35 functions**

## Exported Functions

### Wikipedia Text Fetching
- `get_wikitext_by_name()` - Fetch raw wikitext by article name
- `get_wikitext_by_revid()` - Fetch raw wikitext by revision ID
- `get_wikitext_from_url()` - Fetch wikitext from a Wikipedia URL

### Wikipedia Content Processing
- `extract_clean_fragments()` - Extract clean text fragments from wikitext
- `extract_infobox()` - Extract the first infobox template from wikitext
- `clean_infobox_value()` - Clean a single infobox field value
- `count_citations()` - Count citation templates in wikitext
- `count_refs()` - Count reference tags in wikitext
- `extract_census_years()` - Extract census years from wikitext
- `cache_wikitext()` - Cache wikitext locally

### Wikipedia Categories
- `get_wp_category_members()` - Get members of a Wikipedia category
- `get_wp_subcategories()` - Get subcategories from a category (convenience wrapper)
- `get_wp_category_pages()` - Get pages from a category (convenience wrapper)

### Wikipedia Page Information
- `get_page_info_batch()` - Fetch page metadata in batches

### Wikitext Formatting
- `as_wikitable()` - Format a data frame as a MediaWiki wikitable

### Wikipedia Search & Matching
- `add_wikipedia_matches()` - Add Wikipedia search matches to a data frame

### Wikidata Properties
- `add_wikidata_property()` - Add a Wikidata property to a data frame

### Wikidata Instances
- `get_wikidata_instances()` - Get all instances of a Wikidata class
- `resume_get_wikidata_instances()` - Resume a partially-completed get_wikidata_instances() query
- `simplify_list_columns()` - Simplify single-value list columns in a data frame

### QuickStatements
- `create_quick_statement()` - Create QuickStatements V1 syntax commands
- `add_quick_statement_column()` - Add a QuickStatements column to a data frame
- `add_quick_statement_column_q()` - Add a QuickStatements column with qualifiers to a data frame
- `remove_quick_statement_column()` - Add a QuickStatements column for removing statements

### String Equivalence
- `str_equivalent()` - String comparison that ignores case, accents, whitespace, etc.
- `equivalent_which()` - Find indices of equivalent strings
- `equivalent_match()` - Find equivalent string in a list
- `str_equivalent_list()` - Check for equivalent strings in a list

## Internal Functions (Not Exported)

### Wikidata Instance Retrieval Helpers
- `.extract_numeric_list_property()` - Extract numeric multi-claim property values
- `.extract_instance_or_subclass()` - Extract instance/subclass QIDs
- `.build_sparql_query()` - Build SPARQL query for class retrieval
- `.parse_entity()` - Parse a Wikidata entity record
- `.fetch_qids_in_batches()` - Fetch QIDs from Wikidata in batches
- `.sparql_get_qids()` - Execute SPARQL query and return QIDs

### Wikipedia Text Processing Helpers
- `split_on_top_level_pipes()` - Split text on top-level pipe characters

## Source Files

- `R/add-wikipedia-matches.R` - Wikipedia search functions
- `R/create_quick_statement.R` - QuickStatements generation functions
- `R/get_wikidata_instances.R` - Wikidata instance retrieval functions
- `R/str-equivalent.R` - String equivalence/matching functions
- `R/wikipedia-tools.R` - General Wikipedia tools and utilities
