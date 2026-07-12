# Policy framing derived from the curated hypothesis evidence already bundled
# with the package. The mapping is deliberately explicit so that it can be
# reviewed and extended without changing server logic.
policy_evidence_map <- function() {
  data.table::data.table(
    sdg_id = c("SDG 3", "SDG 4", "SDG 5", "SDG 6"),
    sdg_label = c(
      "Good health and well-being",
      "Quality education",
      "Gender equality",
      "Clean water and sanitation"
    ),
    hypothesis_id = c("H1|H2|H3|H5|H6", "H4", "H8", "H7"),
    evidence_type = c("Direct DHS evidence", "Partial DHS evidence", "Partial DHS evidence", "Direct DHS evidence")
  )[, hypothesis_id := strsplit(hypothesis_id, "|", fixed = TRUE)][, .(hypothesis_id = unlist(hypothesis_id)), by = .(sdg_id, sdg_label, evidence_type)]
}

policy_evidence_summary <- function(timeline, catalogue, mapping = policy_evidence_map()) {
  data.table::setDT(timeline)
  data.table::setDT(catalogue)
  data.table::setDT(mapping)

  latest <- data.table::copy(timeline)[survey_year == latest_year]
  latest <- latest[!duplicated(indicator_id)]
  latest <- merge(latest, mapping, by = "hypothesis_id", all = FALSE)
  latest <- merge(
    latest,
    catalogue[, .(indicator_id, has_ci, has_denominator)],
    by = "indicator_id",
    all.x = TRUE
  )

  summary <- latest[, .(
    evidence_count = data.table::uniqueN(indicator_id),
    latest_year = max(latest_year, na.rm = TRUE),
    improved = sum(progress_status == "Improved", na.rm = TRUE),
    worse = sum(progress_status == "Worse", na.rm = TRUE),
    little_change = sum(progress_status == "Little change", na.rm = TRUE),
    with_ci = sum(has_ci %in% TRUE, na.rm = TRUE),
    with_denominator = sum(has_denominator %in% TRUE, na.rm = TRUE)
  ), by = .(sdg_id, sdg_label, evidence_type)]

  summary[, status := data.table::fcase(
    evidence_count < 2L, "Insufficient evidence",
    improved > worse, "Improving",
    worse > improved, "Worsening",
    default = "Mixed"
  )]
  summary[, caveat := paste0(
    evidence_type,
    "; ", evidence_count, " curated indicators; latest DHS evidence: ", latest_year, "."
  )]
  data.table::setorder(summary, sdg_id)
  summary[]
}

policy_story_rows <- function(timeline, catalogue, selected_sdg, mapping = policy_evidence_map()) {
  ids <- mapping[mapping[["sdg_id"]] == selected_sdg, hypothesis_id]
  out <- data.table::copy(timeline)[hypothesis_id %in% ids & survey_year == latest_year]
  out <- out[!duplicated(indicator_id)]
  merge(out, catalogue[, .(indicator_id, has_ci, has_denominator)], by = "indicator_id", all.x = TRUE)
}

policy_evidence_gaps <- function() {
  data.table::data.table(
    SDG = c("SDG 1", "SDG 7", "SDG 8", "SDG 9", "SDG 10", "SDG 11", "SDG 12", "SDG 13", "SDG 14", "SDG 15", "SDG 16", "SDG 17"),
    DHS_role = c("Proxy only", "Partial proxy", "Limited", "Limited proxy", "Partial", "Partial proxy", "Limited", "Limited", "Not covered", "Not covered", "Limited partial", "Not covered"),
    Gap = c(
      "DHS household conditions do not measure income poverty.",
      "Household electricity access does not measure affordability or clean-energy supply.",
      "Employment, earnings, GDP, and productivity require labour and economic datasets.",
      "Connectivity is a household proxy, not industrialisation or infrastructure quality.",
      "National estimates cannot fully describe inequality between places and groups.",
      "DHS does not measure urban planning, transport, or housing systems.",
      "DHS has no direct coverage of sustainable consumption and production.",
      "Climate exposure, emissions, and adaptation require climate datasets.",
      "No DHS evidence.", "No DHS evidence.",
      "DHS includes selected outcomes but does not measure justice or institutions broadly.",
      "No DHS evidence."
    )
  )
}
