# Package-local cache for app datasets.
.app_data_cache <- new.env(parent = emptyenv())

load_app_data <- function(name) {
  if (!exists(name, envir = .app_data_cache, inherits = FALSE)) {
    utils::data(list = name, package = "kenyaIndicators", envir = .app_data_cache)
    if (!exists(name, envir = .app_data_cache, inherits = FALSE)) {
      stop(
        "Package data object `", name, "` was not found. Run data-raw/my_dataset.R first.",
        call. = FALSE
      )
    }
    if (!inherits(.app_data_cache[[name]], "sf")) {
      data.table::setDT(.app_data_cache[[name]])
    }
  }

  .app_data_cache[[name]]
}

app_dhs_indicators <- function() {
  load_app_data("dhs_indicators")
}

app_indicator_catalogue <- function() {
  load_app_data("indicator_catalogue")
}

app_domain_summary <- function() {
  load_app_data("domain_summary")
}

app_dashboard_pins <- function() {
  load_app_data("dashboard_pins")
}


app_dashboard_timeline <- function() {
  load_app_data("dashboard_timeline")
}
app_indicator_latest <- function() {
  load_app_data("indicator_latest")
}

app_indicator_trends <- function() {
  load_app_data("indicator_trends")
}


app_kenya_counties <- function() {
  load_app_data("kenya_counties")
}
app_hypothesis_map <- function() {
  load_app_data("hypothesis_map")
}
