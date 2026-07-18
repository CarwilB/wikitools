# Functions in wiki-graph NOT in wikitools

Functions found in the wiki-graph project files (those mentioning Wikipedia or Wikidata) that are **not** defined in the wikitools package.

**Total: 141 unique functions**

## By Category

### Data Processing & Cleaning
- `add_ine_code_dept` - Add INE department codes
- `add_ine_code_dept_age` - Add INE codes for departments with age data
- `add_ine_code_muni` - Add INE municipality codes
- `add_ine_code_muni_age` - Add INE codes for municipalities with age data
- `add_ine_code_prov` - Add INE province codes
- `add_ine_code_prov_age` - Add INE codes for provinces with age data
- `attach_ine_codes` - Attach INE codes to data frame
- `clean_facilities_data` - Clean facilities data
- `clean_facility_names` - Clean facility names
- `clean_label` - Clean label text
- `clean_variable_names` - Clean variable names
- `clean_variable_names_from_header` - Clean variable names from header
- `clean_wiki` - Clean wiki text/data
- `disaggregate_tab` - Disaggregate tabular data
- `english_var_name_fix` - Fix English variable names
- `es_var_name_fix` - Fix Spanish variable names
- `parse_tab_headers` - Parse table headers
- `pop_age_en_fix` - Fix English age-related data
- `pop_age_es_fix` - Fix Spanish age-related data
- `read_tab_raw` - Read raw tabular data
- `read_facilities_data` - Read facilities data
- `save_tab` - Save tabular data

### Wikidata & Semantic Web
- `fetch_wikidata_cached` - Fetch Wikidata with caching
- `get_instance_of` - Get instance_of relationships
- `get_wikidata_frequencies` - Get Wikidata property frequencies
- `get_wikidata_qids` - Get Wikidata QIDs
- `get_second_level_classes_v2` - Get second-level Wikidata classes
- `resume_wikidata_instance_wikipedia_presence` - Resume Wikidata/Wikipedia presence analysis
- `wikidata_instance_wikipedia_presence` - Get Wikidata instance Wikipedia presence
- `sparql_query` - Execute SPARQL queries

### Wikipedia Content & Text
- `fetch_wikitext` - Fetch wikitext
- `get_plain_text` - Get plain text from Wikipedia
- `get_plain_text_revid` - Get plain text from a specific revision
- `get_title_from_revid` - Get article title from revision ID
- `wikitext_to_plain` - Convert wikitext to plain text
- `get_wikitable` - Get a wikitable from article
- `check_pages_exist_batch` - Check if Wikipedia pages exist (batch)

### Wikiblame & Edit Tracking
- `find_sentence_insertion` - Find when a sentence was inserted
- `find_sentence_with_map` - Find sentence and its insertion map
- `get_revision_history_map` - Get revision history map
- `get_revision_text_safe` - Safely get revision text
- `track_wikipedia_sentences` - Track sentence history in Wikipedia

### Reference Management (Zotero Integration)
- `add_items_to_collection` - Add items to Zotero collection
- `check_library_for_refs` - Check Zotero library for references
- `dedup_key` - Generate deduplication key for references
- `deduplicate_refs` - Deduplicate references
- `enrich_ref` - Enrich reference metadata
- `enrich_refs` - Enrich multiple references
- `export_ris` - Export references as RIS format
- `extract_all_citations` - Extract all citations
- `extract_authors` - Extract author names
- `extract_bare_refs` - Extract bare references
- `extract_refs_from_wikitext` - Extract references from wikitext
- `extract_templates` - Extract templates from wikitext
- `fetch_zotero_keys` - Fetch Zotero item keys
- `find_template_end` - Find template end position
- `import_to_zotero` - Import references to Zotero
- `itemtype_to_ris` - Convert Zotero item type to RIS type
- `parse_template_params` - Parse template parameters
- `post_refs_to_zotero` - Post references to Zotero API
- `ref_to_ris_lines` - Convert reference to RIS lines
- `ref_to_zotero_item` - Convert reference to Zotero item
- `refs_to_zotero_items` - Convert references to Zotero items
- `template_to_itemtype` - Convert template to Zotero item type
- `template_to_ref` - Convert template to reference
- `wiki_refs_pipeline` - Full pipeline for Wikipedia reference processing

### Wikitext Generation & Formatting
- `build_census_pop_wikitable` - Build census population wikitable
- `build_infobox` - Build Wikipedia infobox
- `build_population_qs_table` - Build population QuickStatements table
- `build_wikitext` - Build wikitext output
- `compose_community_list_wikitext` - Compose community list in wikitext
- `compose_council_sentence_en` - Compose council sentence (English)
- `compose_lead_sentence_en` - Compose lead sentence (English)
- `compose_mayor_sentence_en` - Compose mayor sentence (English)
- `compose_pop_rank_sentence_en` - Compose population rank sentence (English)
- `compose_province_context_en` - Compose province context (English)
- `muni_block` - Create municipality block
- `render_muni_blocks` - Render municipality blocks
- `source_ref_with_page_number` - Add source reference with page number
- `spanish_title_case` - Apply Spanish title case
- `title_case_preserve_de` - Apply title case preserving German articles
- `wikitext_block` - Create wikitext block

### Commons/File Management
- `add_sdc_captions` - Add Structured Data captions to Commons file
- `add_sdc_claim` - Add Structured Data claim to Commons file
- `add_sdc_for_file` - Add Structured Data for file
- `build_descriptions` - Build file descriptions
- `ca_prep` - Prepare Commons upload
- `commons_link` - Create Commons link
- `commons_login` - Login to Wikimedia Commons
- `commons_req` - Make Commons API request
- `commons_thumb` - Create Commons thumbnail
- `edit_file_description` - Edit Commons file description
- `file_exists_on_commons` - Check if file exists on Commons
- `get_csrf_token` - Get CSRF token for Commons
- `upload_file` - Upload file to Commons

### Geographic/Locator Maps
- `extract_hole_near` - Extract hole near a location (for maps)
- `generate_locator_map` - Generate locator map
- `generate_locator_map_external` - Generate external locator map
- `generate_prov_locator_map` - Generate province locator map
- `prepare_shared_layers` - Prepare map layers

### Data Management/Analysis
- `combine_presence_data` - Combine presence data
- `compare_ice_wiki_duplicates` - Compare ICE detention Wikipedia duplicates
- `expand_located_in` - Expand located_in relationships
- `expand_located_in_pd` - Expand located_in (property description version)
- `facilities_wikitable_from_merged` - Create facilities wikitable from merged data
- `facility_mapview` - Create facility mapview
- `facility_mapview_adp` - Create facility mapview (ADP version)
- `fetch_or_resume` - Fetch or resume data collection
- `find_root` - Find root value in hierarchy
- `fix_city_names` - Fix city names
- `get_top_ethnicities` - Get top ethnicities
- `header_rows` - Get header rows
- `load_admin_sheet` - Load admin boundary sheet
- `match_admin_names` - Match admin names
- `normalize_admin_name` - Normalize admin names
- `normalize_place_name` - Normalize place names
- `report_match_status` - Report matching status
- `spot_check_name_matches` - Spot check name matches
- `union_ids` - Union ID lists

### Visualization & Formatting
- `build_pop_pyramid` - Build population pyramid
- `fmt_compact` - Format compactly
- `fmt_coord_range` - Format coordinate range
- `format_for_display` - Format for display
- `make_article_colors` - Create article colors
- `make_cell` - Make table cell
- `make_info_table` - Make info table
- `make_legend_panel` - Make legend panel
- `make_presence_map` - Make presence map
- `make_review_section` - Make review section
- `make_p1082_removals` - Make P1082 (population) removal statements
- `p585_for_year` - Create P585 (point in time) qualifier for year
- `process_for_display` - Process data for display
- `refs_footnotes` - Format references as footnotes
- `render_table` - Render table
- `square_bg` - Create square background element
- `theme_bolivia_map` - Theme Bolivia map
- `text_to_num` - Convert text to number
- `wd_link` - Create Wikidata link

### Wiki Administration
- `create_multiple_redirects_to_one` - Create multiple redirects
- `create_redirect` - Create redirect page
- `aggregate_facilties_data` - Aggregate facilities data
- `make_legend_panel` - Make legend panel
- `make_presence_map` - Make presence map

## Summary

These 141 functions represent specialized domain-specific functionality for:
1. **Data integration** between census data, administrative boundaries, and Wikipedia/Wikidata
2. **Wikipedia article generation** (especially for Bolivian municipalities)
3. **Zotero reference management** integration with Wikipedia
4. **Structured Data** markup for Wikimedia Commons
5. **Geographic/cartographic** work with maps and locator files
6. **Edit tracking** and Wikipedia history analysis
7. **Data normalization** and matching between systems

Many of these would be candidates for inclusion in wikitools if they're commonly reusable utilities.
