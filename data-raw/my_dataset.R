## Code to prepare Kenya DHS national indicators package datasets.
## Heavy work belongs here, not inside Shiny.

library(rhdx)
library(data.table)
library(usethis)

`%||%` <- function(x, y) { if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x }


infer_indicator_unit <- function(indicator, indicator_id = NA_character_, indicator_type = NA_character_) {
  indicator_l <- tolower(as.character(indicator %||% ""))
  id <- as.character(indicator_id %||% NA_character_)
  type <- as.character(indicator_type %||% NA_character_)
  unit <- rep("percent", length(indicator_l))
  unit[grepl("pregnancy-related mortality ratio|maternal mortality ratio", indicator_l)] <- "deaths per 100,000 live births"
  unit[grepl("mortality rate|neonatal mortality|postneonatal mortality|infant mortality|under-five mortality|child mortality", indicator_l)] <- "deaths per 1,000 live births"
  unit[grepl("total fertility rate", indicator_l) | grepl("_TFR$", id)] <- "births per woman"
  unit[grepl("fertility rate", indicator_l) & unit == "percent"] <- "births per 1,000 women"
  unit[grepl("median age|median duration|age at", indicator_l)] <- "years"
  unit[grepl("^number of| number of|\\(weighted\\)|\\(unweighted\\)", indicator_l)] <- "count"
  unit[type %in% c("N", "D", "U") & unit == "percent"] <- "count"
  unit
}

unit_axis_label <- function(unit) {
  out <- as.character(unit %||% "")
  out[out == "percent"] <- "Percent (%)"
  out[out == "count"] <- "Count"
  out[!nzchar(out) | is.na(out)] <- "Value"
  out
}

format_value_with_unit <- function(value, precision = NA_integer_, unit = NA_character_) {
  formatted <- format_value(value, precision)
  unit <- as.character(unit %||% NA_character_)
  if (length(unit) == 1L) unit <- rep(unit, length(formatted))
  paste0(formatted, ifelse(unit == "percent", "%", ""), ifelse(!is.na(unit) & nzchar(unit) & !unit %in% c("percent", "count"), paste0(" ", unit), ""))
}

format_number <- function(x, digits = 0) {
  vapply(x, function(value) {
    if (is.na(value) || !is.finite(value)) return("Not available")
    format(round(value, digits), big.mark = ",", nsmall = digits, trim = TRUE)
  }, character(1))
}

format_value <- function(value, precision = NA_integer_) {
  if (length(precision) == 1L) precision <- rep(precision, length(value))
  vapply(seq_along(value), function(i) {
    digits <- suppressWarnings(as.integer(precision[[i]]))
    if (is.na(digits) || digits < 0 || digits > 4) digits <- 1
    format_number(value[[i]], digits)
  }, character(1))
}

format_change <- function(x, digits = 1) {
  vapply(x, function(value) {
    if (is.na(value) || !is.finite(value)) return("Not available")
    paste0(ifelse(value > 0, "+", ""), format_number(value, digits))
  }, character(1))
}
options(timeout = 300)
set_rhdx_config(hdx_site = "prod")

dataset_slug <- "dhs-data-for-kenya"
raw_dir <- file.path("data-raw", "dhs_hdx")
if (!dir.exists(raw_dir)) {
  dir.create(raw_dir, recursive = TRUE)
}

message("Pulling HDX dataset metadata: ", dataset_slug)
dhs_dataset <- pull_dataset(dataset_slug)
dhs_resources <- get_resources(dhs_dataset)

resource_meta <- rbindlist(lapply(seq_along(dhs_resources), function(i) {
  r <- dhs_resources[[i]]$as_list()
  data.table(
    resource_position = as.integer(r$position %||% (i - 1L)),
    resource_id = r$id %||% NA_character_,
    resource_name = r$name %||% NA_character_,
    resource_description = r$description %||% NA_character_,
    resource_format = r$format %||% NA_character_,
    resource_url = r$url %||% r$download_url %||% NA_character_,
    resource_last_modified = r$last_modified %||% NA_character_,
    resource_size = suppressWarnings(as.numeric(r$size %||% NA_real_))
  )
}), fill = TRUE)

resource_meta <- resource_meta[resource_format == "CSV" | grepl("\\.csv$", resource_url, ignore.case = TRUE)]
resource_meta[, file := basename(resource_url)]
resource_meta[is.na(file) | !nzchar(file), file := paste0(resource_position, "_", gsub("[^A-Za-z0-9]+", "-", tolower(resource_name)), ".csv")]
resource_meta[, local_path := file.path(raw_dir, file)]

message("Downloading/reading ", nrow(resource_meta), " CSV resources")
raw_list <- vector("list", nrow(resource_meta))

for (i in seq_len(nrow(resource_meta))) {
  meta <- resource_meta[i]
  message(sprintf("[%02d/%02d] %s", i, nrow(resource_meta), meta$resource_name))

  if (!file.exists(meta$local_path) || file.info(meta$local_path)$size == 0) {
    downloaded <- FALSE
    for (attempt in 1:3) {
      try(
        {
          download.file(meta$resource_url, meta$local_path, mode = "wb", quiet = TRUE)
          downloaded <- file.exists(meta$local_path) && file.info(meta$local_path)$size > 0
        },
        silent = TRUE
      )
      if (downloaded) break
      Sys.sleep(2 * attempt)
    }
    if (!downloaded) {
      stop("Failed to download resource after 3 attempts: ", meta$resource_url, call. = FALSE)
    }
  }

  dt <- fread(meta$local_path, na.strings = c("", "NA", "NaN"), showProgress = FALSE)

  ## HDX sometimes includes HXL-tag rows; keep data rows only.
  if ("ISO3" %in% names(dt)) {
    dt <- dt[!is.na(ISO3) & !grepl("^#", ISO3)]
  }

  dt[, resource_position := meta$resource_position]
  dt[, resource_id := meta$resource_id]
  dt[, resource_name := meta$resource_name]
  dt[, resource_file := meta$file]
  raw_list[[i]] <- dt
}

dhs_indicators <- rbindlist(raw_list, fill = TRUE, use.names = TRUE)
setnames(dhs_indicators, names(dhs_indicators), make.names(names(dhs_indicators), unique = TRUE))

rename_if_present <- function(dt, old, new) {
  old <- old[old %in% names(dt)]
  new <- new[seq_along(old)]
  if (length(old)) setnames(dt, old, new)
}

rename_if_present(
  dhs_indicators,
  c(
    "ISO3", "DataId", "Indicator", "Value", "Precision", "DHS_CountryCode",
    "CountryName", "SurveyYear", "SurveyId", "IndicatorId", "IndicatorOrder",
    "IndicatorType", "CharacteristicId", "CharacteristicOrder", "CharacteristicCategory",
    "CharacteristicLabel", "ByVariableId", "ByVariableLabel", "IsTotal", "IsPreferred",
    "SDRID", "RegionId", "SurveyYearLabel", "SurveyType", "DenominatorWeighted",
    "DenominatorUnweighted", "CILow", "CIHigh", "LevelRank"
  ),
  c(
    "iso3", "data_id", "indicator", "value", "precision", "dhs_country_code",
    "country_name", "survey_year", "survey_id", "indicator_id", "indicator_order",
    "indicator_type", "characteristic_id", "characteristic_order", "characteristic_category",
    "characteristic_label", "by_variable_id", "by_variable_label", "is_total", "is_preferred",
    "sdr_id", "region_id", "survey_year_label", "survey_type", "denominator_weighted",
    "denominator_unweighted", "ci_low", "ci_high", "level_rank"
  )
)

numeric_cols <- c("value", "precision", "survey_year", "indicator_order", "characteristic_order", "is_total", "is_preferred", "denominator_weighted", "denominator_unweighted", "ci_low", "ci_high", "level_rank")
for (col in intersect(numeric_cols, names(dhs_indicators))) {
  dhs_indicators[, (col) := suppressWarnings(as.numeric(get(col)))]
}

char_cols <- setdiff(names(dhs_indicators), numeric_cols)
for (col in char_cols) {
  set(dhs_indicators, j = col, value = as.character(dhs_indicators[[col]]))
}

domain_lookup <- data.table(
  resource_name = unique(dhs_indicators$resource_name)
)
domain_lookup[, domain_group := fifelse(
  grepl("Quickstats|Mobile|SDGs|MDGs|MICS|FP2020|PMI/RBM", resource_name), "Summary and frameworks",
  fifelse(grepl("Fertility|Family Planning|Maternal|Access to Health Care|Health Insurance", resource_name), "Reproductive, maternal, and access",
  fifelse(grepl("Child Mortality|Immunization|Diarrhea|Birth Registration|acute respiratory|ARI|Orphans", resource_name), "Child health and mortality",
  fifelse(grepl("Anemia|Anthropometry|IYCF|Iodized Salt|Micronutrients|Nutrition", resource_name), "Nutrition",
  fifelse(grepl("HIV|Sexual Intercourse|Male Circumcision|Tobacco", resource_name), "HIV and sexual health",
  fifelse(grepl("Malaria|Insecticide", resource_name), "Malaria",
  fifelse(grepl("Literacy|Education", resource_name), "Education and literacy",
  fifelse(grepl("Water|Toilet|COVID-19 Prevention", resource_name), "WASH and household conditions",
  fifelse(grepl("Gender|COVID-19 Additional", resource_name), "Gender, agency, and COVID context", "Other")))))))))
]

dhs_indicators <- merge(dhs_indicators, domain_lookup, by = "resource_name", all.x = TRUE)

## Analysis fields are static and belong in package data, not Shiny reactives.
dhs_indicators[, analysis_theme := fcase(
  domain_group == "Education and literacy", "Education",
  domain_group == "WASH and household conditions", "WASH",
  domain_group == "Gender, agency, and COVID context", "Gender and agency",
  grepl("insurance|electricity|employment|mobile phone|internet|wealth|household", paste(resource_name, indicator), ignore.case = TRUE), "Household and economy",
  domain_group %chin% c(
    "Reproductive, maternal, and access", "Child health and mortality",
    "HIV and sexual health", "Nutrition", "Malaria", "Other"
  ), "Health",
  default = "Development context"
)]
dhs_indicators[, sex_group := fcase(
  grepl("_W_", indicator_id), "Women",
  grepl("_M_", indicator_id), "Men",
  default = "Overall"
)]
dhs_indicators[, series_family := fifelse(
  sex_group %chin% c("Women", "Men"),
  gsub("_(W|M)_", "_SEX_", indicator_id),
  indicator_id
)]
dhs_indicators[, county_available := !is.na(region_id) & nzchar(trimws(region_id))]

dhs_indicators[, is_total := as.logical(is_total)]
dhs_indicators[, is_preferred := as.logical(is_preferred)]
dhs_indicators[is.na(is_total), is_total := FALSE]
dhs_indicators[is.na(is_preferred), is_preferred := FALSE]
dhs_indicators[, preferred_total_flag := is_total == TRUE & is_preferred == TRUE]
dhs_indicators[, value_label := fifelse(indicator_type == "I", "Indicator value", "Value")]
dhs_indicators[, value_unit := infer_indicator_unit(indicator, indicator_id, indicator_type)]
dhs_indicators[, value_axis_label := unit_axis_label(value_unit)]
dhs_indicators[, indicator_label := indicator]
dhs_indicators[nchar(indicator_label) > 55, indicator_label := paste0(substr(indicator_label, 1, 52), "...")]
dhs_indicators[, plot_group := fifelse(!is.na(by_variable_label) & nzchar(by_variable_label), by_variable_label, characteristic_label)]
dhs_indicators[is.na(plot_group) | !nzchar(plot_group), plot_group := "Total"]

setorder(dhs_indicators, domain_group, resource_position, indicator_order, indicator_id, survey_year)
resource_priority <- function(resource_name) {
  fifelse(
    resource_name == "DHS Quickstats Data for Kenya", 1L,
    fifelse(
      grepl("^Select ", resource_name), 2L,
      fifelse(
        resource_name == "DHS Mobile Data for Kenya", 3L,
        fifelse(grepl("SDGs|MDGs", resource_name), 4L, 5L)
      )
    )
  )
}

canonical_indicator_rows <- function(dt, by_cols = c("indicator_id", "survey_year")) {
  setDT(dt)
  if (nrow(dt) == 0) {
    return(copy(dt))
  }

  out <- copy(dt)
  out[, .resource_priority := resource_priority(resource_name)]
  out[, .denominator_rank := fcoalesce(denominator_weighted, denominator_unweighted, 0)]
  setorderv(
    out,
    c(by_cols, ".resource_priority", "is_preferred", "is_total", ".denominator_rank", "resource_position"),
    c(rep(1L, length(by_cols)), 1L, -1L, -1L, -1L, 1L)
  )
  out <- out[, .SD[1], by = by_cols]
  out[, c(".resource_priority", ".denominator_rank") := NULL]
  out[]
}

total_pref <- dhs_indicators[preferred_total_flag == TRUE]
if (nrow(total_pref) == 0) {
  total_pref <- dhs_indicators[is_total == TRUE]
}

indicator_catalogue <- dhs_indicators[, .(
  resource_position = first(resource_position),
  resource_id = first(resource_id),
  resource_file = first(resource_file),
  domain_group = first(domain_group),
  analysis_theme = first(analysis_theme),
  series_family = first(series_family),
  sex_group = first(sex_group),
  county_available = any(county_available),
  indicator = first(indicator),
  indicator_label = first(indicator_label),
  indicator_type = first(indicator_type),
  value_unit = first(value_unit),
  value_axis_label = first(value_axis_label),
  rows = .N,
  year_count = uniqueN(survey_year[!is.na(survey_year)]),
  years_available = paste(sort(unique(survey_year[!is.na(survey_year)])), collapse = ", "),
  min_year = min(survey_year, na.rm = TRUE),
  latest_year = max(survey_year, na.rm = TRUE),
  breakdowns_available = paste(sort(unique(by_variable_label[!is.na(by_variable_label) & nzchar(by_variable_label)])), collapse = "; "),
  characteristics_available = paste(sort(unique(characteristic_category[!is.na(characteristic_category) & nzchar(characteristic_category)])), collapse = "; "),
  has_ci = any(!is.na(ci_low) & !is.na(ci_high)),
  has_denominator = any(!is.na(denominator_weighted) | !is.na(denominator_unweighted))
), by = .(indicator_id, resource_name)]

## One catalogue row per indicator for app selectors; keep the richest resource row.
setorder(indicator_catalogue, indicator_id, -rows)
indicator_catalogue <- indicator_catalogue[, .SD[1], by = indicator_id]
setorder(indicator_catalogue, domain_group, indicator)

indicator_latest <- total_pref[order(survey_year), .SD[.N], by = indicator_id]
indicator_latest <- indicator_latest[, .(
  indicator_id, indicator, indicator_label, domain_group, resource_name, survey_year,
  value, precision, value_unit, value_axis_label, ci_low, ci_high, denominator_weighted, denominator_unweighted
)]

indicator_trends <- total_pref[order(survey_year), {
  baseline <- .SD[1]
  latest_row <- .SD[.N]
  .(
    indicator = latest_row$indicator,
    indicator_label = latest_row$indicator_label,
    domain_group = latest_row$domain_group,
    resource_name = latest_row$resource_name,
    precision = latest_row$precision,
    baseline_year = baseline$survey_year,
    baseline_value = baseline$value,
    latest_year = latest_row$survey_year,
    latest_value = latest_row$value,
    change_from_baseline = latest_row$value - baseline$value,
    observations = .N
  )
}, by = indicator_id]

indicator_trends <- merge(indicator_trends, indicator_catalogue[, .(indicator_id, value_unit, value_axis_label)], by = "indicator_id", all.x = TRUE)
indicator_trends[, pct_change_from_baseline := fifelse(!is.na(baseline_value) & baseline_value != 0, 100 * change_from_baseline / abs(baseline_value), NA_real_)]

resource_counts <- dhs_indicators[, .(
  resources = uniqueN(resource_name),
  indicators = uniqueN(indicator_id),
  rows = .N,
  min_year = min(survey_year, na.rm = TRUE),
  max_year = max(survey_year, na.rm = TRUE),
  latest_year = max(survey_year, na.rm = TRUE)
), by = domain_group]
setorder(resource_counts, domain_group)
domain_summary <- resource_counts

pin_ids <- c(
  "FE_FRTR_W_TFR", "FP_CUSM_W_MOD", "FP_NADM_W_UNT", "CM_ECMR_C_U5M",
  "CM_ECMR_C_IMR", "CH_VACC_C_BAS", "RH_DELP_C_DHF", "CN_NUTS_C_HA2",
  "ML_NETC_C_ITN", "HA_CPHT_W_T1R", "ED_EDUC_W_SEH", "WS_SRCE_P_IMP",
  "WS_TLET_P_IMP", "HC_ELEC_H_ELC", "DV_SPVL_W_POS", "FG_PFCC_W_WCC"
)
dashboard_pins <- data.table(
  pin_order = seq_along(pin_ids),
  indicator_id = pin_ids,
  hypothesis_id = c("H1", "H1", "H1", "H2", "H2", "H2", "H3", "H2", "H6", "H5", "H4", "H7", "H7", "H7", "H8", "H8")
)
dashboard_pins <- dashboard_pins[indicator_id %in% indicator_catalogue$indicator_id]

hypothesis_map <- rbindlist(list(
  data.table(hypothesis_id = "H1", hypothesis_label = "Fertility transition", hypothesis_claim = "Fertility decline is connected to increased modern contraception and reduced unmet need.", interpretation_rule = "Look for fertility falling while modern method use and demand satisfied rise.", evidence_role = c("Outcome", "Driver", "Gap"), indicator_id = c("FE_FRTR_W_TFR", "FP_CUSM_W_MOD", "FP_NADM_W_UNT")),
  data.table(hypothesis_id = "H2", hypothesis_label = "Child survival pathway", hypothesis_claim = "Child survival improved alongside immunization, diarrhea treatment, nutrition, WASH, and malaria prevention.", interpretation_rule = "Look for mortality falling as protective indicators improve.", evidence_role = c("Outcome", "Outcome", "Protection", "Nutrition", "Malaria"), indicator_id = c("CM_ECMR_C_U5M", "CM_ECMR_C_IMR", "CH_VACC_C_BAS", "CN_NUTS_C_HA2", "ML_NETC_C_ITN")),
  data.table(hypothesis_id = "H3", hypothesis_label = "Maternal care access", hypothesis_claim = "Maternal and newborn outcomes are linked to service access and facility delivery.", interpretation_rule = "Look for facility delivery and access indicators improving while mortality indicators decline.", evidence_role = c("Service", "Outcome"), indicator_id = c("RH_DELP_C_DHF", "MM_MMRO_W_PMR")),
  data.table(hypothesis_id = "H4", hypothesis_label = "Education and agency", hypothesis_claim = "Education, literacy, media access, and digital access shape health knowledge and autonomy.", interpretation_rule = "Look for aligned gains in education, literacy, media access, and autonomy indicators.", evidence_role = c("Education", "Literacy", "Agency"), indicator_id = c("ED_EDUC_W_SEH", "ED_LITR_W_LIT", "WE_DMAK_W_OHC")),
  data.table(hypothesis_id = "H5", hypothesis_label = "HIV risk transition", hypothesis_claim = "HIV risk has shifted from awareness gaps to behavior, testing, stigma, and service uptake gaps.", interpretation_rule = "Compare knowledge, testing, attitudes, behavior, and prevalence indicators together.", evidence_role = c("Testing", "Prevalence women", "Prevalence men"), indicator_id = c("HA_CPHT_W_T1R", "HA_HIVP_W_HIV", "HA_HIVP_M_HIV")),
  data.table(hypothesis_id = "H6", hypothesis_label = "Malaria ownership-to-use", hypothesis_claim = "Malaria protection depends on ownership-to-use conversion, not only availability of ITNs.", interpretation_rule = "Compare ITN ownership and actual use among children or pregnant women.", evidence_role = c("Use", "Parasitemia"), indicator_id = c("ML_NETC_C_ITN", "ML_PARC_C_PLM")),
  data.table(hypothesis_id = "H7", hypothesis_label = "WASH and household risk", hypothesis_claim = "WASH and household living conditions are cross-cutting risk factors for child health, nutrition, and COVID prevention.", interpretation_rule = "Look for persistent gaps in water, sanitation, handwashing, electricity, and crowding.", evidence_role = c("Water", "Sanitation", "Electricity"), indicator_id = c("WS_SRCE_P_IMP", "WS_TLET_P_IMP", "HC_ELEC_H_ELC")),
  data.table(hypothesis_id = "H8", hypothesis_label = "Gender, autonomy, and safety", hypothesis_claim = "Gender autonomy and violence indicators should be treated as central outcomes, not side notes.", interpretation_rule = "Inspect autonomy, partner violence, and FGC trends with careful survey caveats.", evidence_role = c("Autonomy", "Violence", "FGC"), indicator_id = c("WE_DMAK_W_OHC", "DV_SPVL_W_POS", "FG_PFCC_W_WCC"))
), fill = TRUE)
hypothesis_map <- hypothesis_map[indicator_id %in% indicator_catalogue$indicator_id]
dashboard_direction <- data.table(
  indicator_id = pin_ids,
  desirable_direction = c(
    -1, 1, -1, -1,
    -1, 1, 1, -1,
    1, 1, 1, 1,
    1, 1, -1, -1
  )
)

dashboard_timeline <- total_pref[indicator_id %in% dashboard_pins$indicator_id]
dashboard_timeline <- canonical_indicator_rows(
  dashboard_timeline,
  by_cols = c("indicator_id", "survey_year")
)
dashboard_timeline <- merge(
  dashboard_pins,
  dashboard_timeline,
  by = "indicator_id",
  all.x = TRUE,
  allow.cartesian = TRUE
)
dashboard_timeline <- merge(
  dashboard_timeline,
  hypothesis_map[, .(hypothesis_id, indicator_id, hypothesis_label, evidence_role)],
  by = c("hypothesis_id", "indicator_id"),
  all.x = TRUE
)
dashboard_timeline <- merge(
  dashboard_timeline,
  dashboard_direction,
  by = "indicator_id",
  all.x = TRUE
)
dashboard_timeline[is.na(desirable_direction), desirable_direction := 1]
setorder(dashboard_timeline, pin_order, survey_year)
dashboard_timeline[, baseline_year := survey_year[which(!is.na(value))[1]], by = indicator_id]
dashboard_timeline[, baseline_value := value[which(!is.na(value))[1]], by = indicator_id]
dashboard_timeline[, latest_year := max(survey_year, na.rm = TRUE), by = indicator_id]
dashboard_timeline[, change_from_baseline := value - baseline_value]
dashboard_timeline[, pct_change_from_baseline := fifelse(!is.na(baseline_value) & baseline_value != 0, 100 * change_from_baseline / abs(baseline_value), NA_real_)]
dashboard_timeline[, progress_score := desirable_direction * change_from_baseline]
dashboard_timeline[, progress_pct_from_baseline := desirable_direction * pct_change_from_baseline]
dashboard_timeline[, desired_direction_label := fifelse(desirable_direction >= 0, "higher is better", "lower is better")]
dashboard_timeline[, indexed_value := fifelse(
  !is.na(baseline_value) & baseline_value != 0,
  100 * value / baseline_value,
  NA_real_
)]
dashboard_timeline[, progress_status := fifelse(
  is.na(progress_pct_from_baseline), "No estimate",
  fifelse(abs(progress_pct_from_baseline) < 2, "Little change",
    fifelse(progress_pct_from_baseline > 0, "Improved", "Worse")
  )
)]
dashboard_timeline[, evidence_label := paste0(hypothesis_id, " | ", indicator_label)]
dashboard_timeline[, tooltip := paste0(
  hypothesis_id, ": ", hypothesis_label,
  "\n", evidence_role, " evidence",
  "\n", indicator,
  "\nYear: ", survey_year,
  "\nValue: ", format_value_with_unit(value, precision, value_unit),
  "\nBaseline year: ", baseline_year,
  "\nNative-unit change: ", format_change(change_from_baseline, 1),
  "\nProgress from baseline: ", format_change(progress_pct_from_baseline, 1), "%",
  "\nDirection rule: ", desired_direction_label,
  "\nStatus: ", progress_status
)]
dashboard_timeline <- dashboard_timeline[, .(
  pin_order, hypothesis_id, hypothesis_label, evidence_role,
  indicator_id, indicator, indicator_label, evidence_label, domain_group,
  survey_year, baseline_year, latest_year, value, precision, baseline_value,
  change_from_baseline, pct_change_from_baseline, indexed_value, progress_score, progress_pct_from_baseline,
  progress_status, desirable_direction, desired_direction_label, value_unit, value_axis_label, tooltip
)]

usethis::use_data(dhs_indicators, overwrite = TRUE)
usethis::use_data(indicator_catalogue, overwrite = TRUE)
usethis::use_data(domain_summary, overwrite = TRUE)
usethis::use_data(indicator_latest, overwrite = TRUE)
usethis::use_data(indicator_trends, overwrite = TRUE)
usethis::use_data(dashboard_pins, overwrite = TRUE)
usethis::use_data(dashboard_timeline, overwrite = TRUE)

kenya_geojson <- file.path("data-raw", "geoBoundaries-KEN-ADM1_simplified.geojson")
if (!file.exists(kenya_geojson)) {
  download.file(
    "https://github.com/wmgeolab/geoBoundaries/raw/9469f09/releaseData/gbOpen/KEN/ADM1/geoBoundaries-KEN-ADM1_simplified.geojson",
    kenya_geojson,
    mode = "wb",
    quiet = TRUE
  )
}
if (requireNamespace("sf", quietly = TRUE)) {
  kenya_counties <- sf::st_read(kenya_geojson, quiet = TRUE)
  kenya_counties <- sf::st_make_valid(kenya_counties)
}
usethis::use_data(hypothesis_map, overwrite = TRUE)
if (exists("kenya_counties")) usethis::use_data(kenya_counties, overwrite = TRUE)

if (requireNamespace("checkhelper", quietly = TRUE)) {
  checkhelper::fix_dataset_doc("dhs_indicators", overwrite = TRUE)
  checkhelper::fix_dataset_doc("indicator_catalogue", overwrite = TRUE)
  checkhelper::fix_dataset_doc("domain_summary", overwrite = TRUE)
  checkhelper::fix_dataset_doc("indicator_latest", overwrite = TRUE)
  checkhelper::fix_dataset_doc("indicator_trends", overwrite = TRUE)
  checkhelper::fix_dataset_doc("dashboard_pins", overwrite = TRUE)
  checkhelper::fix_dataset_doc("dashboard_timeline", overwrite = TRUE)
  checkhelper::fix_dataset_doc("hypothesis_map", overwrite = TRUE)
}
