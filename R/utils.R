`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x
}

normalise_region_key <- function(x) {
  x <- tolower(trimws(as.character(x)))
  gsub("[^a-z0-9]", "", x)
}
format_number <- function(x, digits = 0) {
  if (length(x) == 0) {
    return("Not available")
  }

  vapply(
    x,
    function(value) {
      if (is.na(value) || !is.finite(value)) {
        return("Not available")
      }
      format(round(value, digits), big.mark = ",", nsmall = digits, trim = TRUE)
    },
    character(1)
  )
}

format_value <- function(value, precision = NA_integer_) {
  if (length(precision) == 1L) {
    precision <- rep(precision, length(value))
  }

  vapply(
    seq_along(value),
    function(i) {
      digits <- suppressWarnings(as.integer(precision[[i]]))
      if (is.na(digits) || digits < 0 || digits > 4) {
        digits <- 1
      }
      format_number(value[[i]], digits)
    },
    character(1)
  )
}

format_change <- function(x, digits = 1) {
  if (length(x) == 0) {
    return("Not available")
  }

  vapply(
    x,
    function(value) {
      if (is.na(value) || !is.finite(value)) {
        return("Not available")
      }
      paste0(ifelse(value > 0, "+", ""), format_number(value, digits))
    },
    character(1)
  )
}


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
  dplyr_unit <- as.character(unit %||% "")
  out <- dplyr_unit
  out[out == "percent"] <- "Percent (%)"
  out[out == "count"] <- "Count"
  out[!nzchar(out) | is.na(out)] <- "Value"
  out
}

format_value_with_unit <- function(value, precision = NA_integer_, unit = NA_character_) {
  formatted <- format_value(value, precision)
  unit <- as.character(unit %||% NA_character_)
  if (length(unit) == 1L) {
    unit <- rep(unit, length(formatted))
  }
  paste0(
    formatted,
    ifelse(unit == "percent", "%", ""),
    ifelse(!is.na(unit) & nzchar(unit) & !unit %in% c("percent", "count"), paste0(" ", unit), "")
  )
}

plot_svg_size <- function(n_items = 1, n_series = 1, base_width = 9.5, base_height = 4.8, per_item = 0.32, per_series = 0.1, max_height = 9.5) {
  n_items <- max(1, as.integer(n_items %||% 1L))
  n_series <- max(1, as.integer(n_series %||% 1L))
  list(
    width = base_width,
    height = min(max_height, max(base_height, base_height + (n_items - 6) * per_item + (n_series - 2) * per_series))
  )
}

overview_panel_columns <- function(width) {
  if (is.null(width) || !is.finite(width)) return(2L)
  if (width >= 1600) return(4L)
  if (width >= 1000) return(3L)
  2L
}

balanced_panel_columns <- function(max_columns, n_items) {
  max_columns <- max(1L, as.integer(max_columns))
  n_items <- max(1L, as.integer(n_items))
  if (max_columns <= 3L || n_items <= 4L) return(min(max_columns, n_items))

  candidates <- 3L:max_columns
  empty_cells <- candidates * ceiling(n_items / candidates) - n_items
  candidates[which.min(empty_cells)]
}
standard_girafe <- function(p, width_svg, height_svg, hover_css = "stroke-width:3px;", selectable = FALSE, rescale = TRUE) {
  options <- list(
    ggiraph::opts_hover(css = hover_css),
    ggiraph::opts_hover_key(css = hover_css),
    ggiraph::opts_tooltip(css = "background:#132f2f;color:white;padding:10px;border-radius:5px;font-size:14px;line-height:1.28;"),
    ggiraph::opts_sizing(rescale = rescale, width = 1)
  )
  if (isTRUE(selectable)) {
    options <- c(
      options,
      list(ggiraph::opts_selection(css = "stroke:#f2a541;stroke-width:4px;", type = "single"))
    )
  }

  ggiraph::girafe(
    ggobj = p,
    width_svg = width_svg,
    height_svg = height_svg,
    pointsize = 15,
    options = options
  )
}
kpi_card <- function(label, value, note = NULL, status = "", input_id = NULL, selected = FALSE) {
  contents <- shiny::tagList(
    shiny::div(class = "ki-kpi-label", label),
    shiny::div(class = "ki-kpi-value", value),
    if (!is.null(note)) shiny::div(class = "ki-kpi-note", note)
  )
  classes <- paste(
    "ki-kpi",
    status,
    if (!is.null(input_id)) "ki-kpi-button" else "",
    if (isTRUE(selected)) "is-selected" else ""
  )

  if (is.null(input_id)) return(shiny::div(class = classes, contents))

  shiny::actionButton(
    input_id,
    label = contents,
    class = classes,
    `aria-pressed` = if (isTRUE(selected)) "true" else "false"
  )
}

datatable_compact <- function(data, page_length = 8, scroll_y = NULL) {
  options <- list(
    pageLength = page_length,
    dom = "tip",
    autoWidth = TRUE,
    scrollX = TRUE
  )
  if (!is.null(scroll_y)) {
    options$scrollY <- scroll_y
    options$scrollCollapse <- TRUE
  }

  DT::datatable(
    data,
    rownames = FALSE,
    filter = "top",
    options = options
  )
}

first_available <- function(x) {
  x <- x[!is.na(x) & nzchar(as.character(x))]
  if (length(x) == 0) NA_character_ else as.character(x[1])
}

resource_priority <- function(resource_name) {
  data.table::fifelse(
    resource_name == "DHS Quickstats Data for Kenya", 1L,
    data.table::fifelse(
      grepl("^Select ", resource_name), 2L,
      data.table::fifelse(
        resource_name == "DHS Mobile Data for Kenya", 3L,
        data.table::fifelse(grepl("SDGs|MDGs", resource_name), 4L, 5L)
      )
    )
  )
}

canonical_indicator_rows <- function(dt, by_cols = c("indicator_id", "survey_year")) {
  data.table::setDT(dt)
  if (nrow(dt) == 0) {
    return(data.table::copy(dt))
  }

  out <- data.table::copy(dt)
  out[, .resource_priority := resource_priority(resource_name)]
  out[, .denominator_rank := data.table::fcoalesce(denominator_weighted, denominator_unweighted, 0)]
  data.table::setorderv(
    out,
    c(by_cols, ".resource_priority", "is_preferred", "is_total", ".denominator_rank", "resource_position"),
    c(rep(1L, length(by_cols)), 1L, -1L, -1L, -1L, 1L)
  )
  out <- out[, .SD[1], by = by_cols]
  out[, c(".resource_priority", ".denominator_rank") := NULL]
  out[]
}

unique_named_choices <- function(dt) {
  data.table::setDT(dt)
  choice_dt <- data.table::copy(dt)[order(indicator)]
  choice_dt <- choice_dt[!duplicated(indicator_id)]
  stats::setNames(choice_dt$indicator_id, paste(choice_dt$indicator, "[", choice_dt$indicator_id, "]"))
}
