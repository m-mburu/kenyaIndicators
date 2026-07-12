wrap_short <- function(x, width = 24, max_chars = 58) {
  vapply(
    x,
    function(value) {
      value <- as.character(value %||% "")
      if (nchar(value) > max_chars) {
        value <- paste0(substr(value, 1, max_chars - 3), "...")
      }
      paste(strwrap(value, width = width), collapse = "\n")
    },
    character(1)
  )
}

empty_girafe <- function(message) {
  p <- ggplot2::ggplot() +
    ggplot2::theme_void(base_size = 13) +
    ggplot2::annotate("text", x = 0, y = 0, label = message, color = "#667085", size = 4.5)

  standard_girafe(p, width_svg = 8, height_svg = 4.8)
}

plot_unit <- function(dt) {
  if ("value_unit" %in% names(dt)) {
    unit <- first_available(dt$value_unit)
    if (!is.na(unit)) return(unit)
  }
  infer_indicator_unit(first_available(dt$indicator), first_available(dt$indicator_id), first_available(dt$indicator_type))[1]
}

make_trend_plot <- function(dt, title = NULL) {
  data.table::setDT(dt)
  validate_plot_data <- nrow(dt) > 0 && uniqueN(dt$survey_year) > 1
  if (!validate_plot_data) {
    return(empty_girafe("Not enough data for a trend"))
  }

  dt <- copy(dt)[order(survey_year)]
  optional_columns <- list(
    plot_group = "National estimate",
    characteristic_label = NA_character_,
    by_variable_label = NA_character_,
    ci_low = NA_real_,
    ci_high = NA_real_,
    denominator_weighted = NA_real_,
    precision = NA_real_
  )
  for (column in names(optional_columns)) {
    if (!column %in% names(dt)) dt[, (column) := optional_columns[[column]]]
  }
  group_count <- data.table::uniqueN(dt$plot_group)
  unit <- plot_unit(dt)
  dt[, value_text := format_value_with_unit(value, precision, unit)]
  dt[, tooltip := paste0(
    indicator,
    "\nSurvey year: ", survey_year,
    "\nValue: ", value_text,
    ifelse(!is.na(characteristic_label) & nzchar(characteristic_label), paste0("\nGroup: ", characteristic_label), ""),
    ifelse(!is.na(by_variable_label) & nzchar(by_variable_label), paste0("\nBreakdown: ", by_variable_label), ""),
    ifelse(!is.na(ci_low) & !is.na(ci_high), paste0("\nCI: ", format_number(ci_low, 1), " - ", format_number(ci_high, 1)), ""),
    ifelse(!is.na(denominator_weighted), paste0("\nWeighted n: ", format_number(denominator_weighted, 0)), "")
  )]

  p <- ggplot2::ggplot(
    dt,
    ggplot2::aes(
      x = survey_year,
      y = value,
      group = plot_group,
      color = plot_group
    )
  ) +
    ggiraph::geom_line_interactive(ggplot2::aes(tooltip = plot_group), linewidth = 1.05, alpha = 0.92) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(tooltip = tooltip, data_id = paste(indicator_id, survey_year, plot_group, sep = "-")),
      size = 3
    ) +
    ggplot2::labs(
      title = title %||% first_available(dt$indicator),
      x = NULL,
      y = unit_axis_label(unit),
      color = NULL
    ) +
    ggplot2::scale_color_manual(values = rep(c("#007c89", "#bc5090", "#f2a541", "#58508d", "#2f4b7c", "#23845f", "#c43b2b"), 20)) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      legend.position = if (group_count > 1) "bottom" else "none",
      legend.text = ggplot2::element_text(size = 9.5),
      plot.title = ggplot2::element_text(face = "bold", color = "#132f2f", size = 14),
      axis.title = ggplot2::element_text(size = 11),
      axis.text = ggplot2::element_text(size = 10, color = "#344054"),
      panel.grid.major.y = ggplot2::element_line(color = "#e5e7eb", linewidth = 0.35),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(10, 18, 10, 10)
    )

  size <- plot_svg_size(data.table::uniqueN(dt$plot_group), data.table::uniqueN(dt$plot_group), base_width = 9.8, base_height = 5.2, per_item = 0.16)
  standard_girafe(p, size$width, size$height)
}

make_long_run_signal_plot <- function(dt, title = "Long-run indicator trends", top_n = 8, ncol = 4) {
  data.table::setDT(dt)
  if (nrow(dt) == 0 || data.table::uniqueN(dt$survey_year[!is.na(dt$survey_year)]) <= 1) {
    return(empty_girafe("Not enough data for long-run trends"))
  }

  plot_dt <- data.table::copy(dt)[!is.na(value) & !is.na(survey_year)]
  plot_dt[, year_count := data.table::uniqueN(survey_year), by = indicator_id]
  plot_dt[, first_year := min(survey_year, na.rm = TRUE), by = indicator_id]
  plot_dt <- plot_dt[year_count >= 4]
  if (nrow(plot_dt) == 0) {
    plot_dt <- data.table::copy(dt)[!is.na(value) & !is.na(survey_year)]
    plot_dt[, year_count := data.table::uniqueN(survey_year), by = indicator_id]
    plot_dt[, first_year := min(survey_year, na.rm = TRUE), by = indicator_id]
    plot_dt <- plot_dt[year_count >= 3]
  }
  if (nrow(plot_dt) == 0) {
    return(empty_girafe("No repeated long-run indicators available"))
  }

  selected_ids <- plot_dt[order(first_year, pin_order), unique(indicator_id)]
  selected_ids <- utils::head(selected_ids, top_n)
  plot_dt <- plot_dt[indicator_id %in% selected_ids]
  data.table::setorder(plot_dt, pin_order, survey_year)
  plot_dt[, baseline_value := value[which(!is.na(value))[1]], by = indicator_id]
  if (nrow(plot_dt) == 0) {
    return(empty_girafe("No trend values available"))
  }

  plot_dt[, signal_label := wrap_short(indicator_label, width = 25, max_chars = 62)]
  plot_dt[, signal_label := factor(signal_label, levels = unique(signal_label))]
  plot_dt[, latest_status := progress_status[.N], by = indicator_id]
  plot_dt[, latest_status := factor(latest_status, levels = c("Improved", "Little change", "Worse", "No estimate"))]
  plot_dt[, tooltip := paste0(
    indicator,
    "\nSurvey year: ", survey_year,
    "\nValue: ", format_value_with_unit(value, precision, value_unit),
    "\nLatest status: ", latest_status,
    "\nDirection rule: ", desired_direction_label
  )]

  year_breaks <- pretty(range(plot_dt$survey_year, na.rm = TRUE), n = 4)
  year_breaks <- year_breaks[year_breaks >= min(plot_dt$survey_year, na.rm = TRUE) & year_breaks <= max(plot_dt$survey_year, na.rm = TRUE)]
  if (length(year_breaks) < 2) {
    year_breaks <- range(plot_dt$survey_year, na.rm = TRUE)
  }

  p <- ggplot2::ggplot(plot_dt, ggplot2::aes(x = survey_year, y = value, group = indicator_id, color = latest_status)) +
    ggiraph::geom_line_interactive(
      ggplot2::aes(tooltip = paste(indicator, latest_status, sep = "\nStatus: "), data_id = indicator_id),
      linewidth = 0.9,
      alpha = 0.95
    ) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(tooltip = tooltip, data_id = indicator_id),
      size = 2.1
    ) +
    ggplot2::facet_wrap(ggplot2::vars(signal_label), ncol = ncol, scales = "free_y") +
    ggplot2::scale_color_manual(
      values = c("Improved" = "#007c89", "Little change" = "#f2c94c", "Worse" = "#bc5090", "No estimate" = "#98a2b3"),
      drop = FALSE,
      name = NULL
    ) +
    ggplot2::scale_x_continuous(breaks = year_breaks, minor_breaks = NULL) +
    ggplot2::labs(
      title = title,
      subtitle = "Select a trend for its detailed indicator view. Panels use independent value scales.",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_void(base_size = 11) +
    ggplot2::theme(
      legend.position = "none",
      plot.title = ggplot2::element_text(face = "bold", color = "#132f2f", size = 14.5),
      plot.subtitle = ggplot2::element_text(color = "#667085", size = 10.5),
      strip.text = ggplot2::element_text(face = "bold", color = "#132f2f", size = 9.5, lineheight = 0.98),
      axis.title = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      panel.spacing = grid::unit(10, "pt"),
      plot.margin = ggplot2::margin(8, 10, 8, 8)
    )

  rows <- ceiling(data.table::uniqueN(plot_dt$indicator_id) / ncol)
  standard_girafe(
    p,
    width_svg = ncol * 3.75,
    height_svg = 1.55 + rows * 2.55,
    hover_css = "stroke:#f2a541;stroke-width:3px;cursor:pointer;",
    selectable = TRUE,
    rescale = TRUE
  )
}
make_indexed_trend_plot <- function(dt, title = "Indexed trend") {
  data.table::setDT(dt)
  if (nrow(dt) == 0 || uniqueN(dt$survey_year) <= 1) {
    return(empty_girafe("Not enough data for a trend"))
  }

  plot_dt <- copy(dt)[!is.na(value)][order(plot_group, survey_year)]
  group_count <- data.table::uniqueN(plot_dt$plot_group)
  unit <- plot_unit(plot_dt)
  plot_dt[, baseline_value := value[which(!is.na(value))[1]], by = plot_group]
  plot_dt <- plot_dt[!is.na(baseline_value) & baseline_value != 0]
  if (nrow(plot_dt) == 0) {
    return(empty_girafe("No non-zero baseline values available"))
  }

  plot_dt[, indexed_value := 100 * value / baseline_value]
  plot_dt[, tooltip := paste0(
    indicator,
    "\nSurvey year: ", survey_year,
    "\nActual value: ", format_value_with_unit(value, precision, unit),
    "\nIndexed value: ", format_number(indexed_value, 1),
    "\nBaseline: 100"
  )]

  p <- ggplot2::ggplot(
    plot_dt,
    ggplot2::aes(x = survey_year, y = indexed_value, group = plot_group, color = plot_group)
  ) +
    ggplot2::geom_hline(yintercept = 100, linewidth = 0.45, color = "#c8d0d8") +
    ggiraph::geom_line_interactive(ggplot2::aes(tooltip = plot_group), linewidth = 1.1, alpha = 0.92) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(tooltip = tooltip, data_id = paste(indicator_id, survey_year, plot_group, sep = "-")),
      size = 3
    ) +
    ggplot2::labs(
      title = title,
      subtitle = "Each indicator is indexed to 100 at its first available survey year",
      x = NULL,
      y = NULL,
      color = NULL
    ) +
    ggplot2::scale_color_manual(values = rep(c("#007c89", "#bc5090", "#f2a541", "#58508d", "#2f4b7c", "#23845f", "#c43b2b", "#d45087"), 20)) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      legend.position = if (group_count > 1) "bottom" else "none",
      legend.text = ggplot2::element_text(size = 9.5),
      plot.title = ggplot2::element_text(face = "bold", color = "#132f2f", size = 14),
      plot.subtitle = ggplot2::element_text(color = "#667085", size = 10.5),
      axis.title = ggplot2::element_text(size = 11),
      axis.text = ggplot2::element_text(size = 10, color = "#344054"),
      panel.grid.major.y = ggplot2::element_line(color = "#e5e7eb", linewidth = 0.35),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(10, 18, 10, 10)
    )

  size <- plot_svg_size(data.table::uniqueN(plot_dt$plot_group), data.table::uniqueN(plot_dt$plot_group), base_width = 9.8, base_height = 5.4, per_item = 0.18)
  standard_girafe(p, size$width, size$height)
}

make_pinned_evidence_plot <- function(dt, title = "Pinned evidence status by survey year") {
  data.table::setDT(dt)
  if (nrow(dt) == 0 || data.table::uniqueN(dt$survey_year[!is.na(dt$survey_year)]) == 0) {
    return(empty_girafe("No pinned evidence available"))
  }

  plot_dt <- data.table::copy(dt)[!is.na(survey_year) & !is.na(value)]
  if (nrow(plot_dt) == 0) {
    return(empty_girafe("No estimates available for selected years"))
  }
  group_count <- data.table::uniqueN(plot_dt$plot_group)

  data.table::setorder(plot_dt, pin_order, survey_year)
  plot_dt[, evidence_short := wrap_short(evidence_label, width = 32, max_chars = 76)]
  plot_dt[, evidence_short := factor(evidence_short, levels = rev(unique(evidence_short)))]
  plot_dt[, survey_year_label := as.character(survey_year)]
  plot_dt[, progress_status := factor(
    progress_status,
    levels = c("Improved", "Little change", "Worse", "No estimate")
  )]

  latest_dt <- plot_dt[survey_year == latest_year]

  p <- ggplot2::ggplot(
    plot_dt,
    ggplot2::aes(x = survey_year_label, y = evidence_short)
  ) +
    ggiraph::geom_tile_interactive(
      ggplot2::aes(
        fill = progress_status,
        tooltip = tooltip,
        data_id = paste(indicator_id, survey_year, sep = "-")
      ),
      color = "white",
      linewidth = 0.7,
      width = 0.88,
      height = 0.74
    ) +
    ggiraph::geom_point_interactive(
      data = latest_dt,
      ggplot2::aes(
        tooltip = tooltip,
        data_id = paste("latest", indicator_id, survey_year, sep = "-")
      ),
      inherit.aes = TRUE,
      shape = 21,
      fill = "#111827",
      color = "white",
      stroke = 0.4,
      size = 2.1
    ) +
    ggplot2::scale_fill_manual(
      values = c(
        "Improved" = "#007c89",
        "Little change" = "#f2c94c",
        "Worse" = "#bc5090",
        "No estimate" = "#d0d5dd"
      ),
      drop = FALSE,
      name = NULL
    ) +
    ggplot2::scale_x_discrete(position = "top") +
    ggplot2::labs(
      title = title,
      subtitle = "Overview first: color shows progress direction from baseline; dot marks the latest estimate.",
      x = NULL,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 13) +
    ggplot2::theme(
      legend.position = if (group_count > 1) "bottom" else "none",
      legend.text = ggplot2::element_text(size = 10),
      legend.key.width = grid::unit(22, "pt"),
      plot.title = ggplot2::element_text(face = "bold", color = "#132f2f", size = 14),
      plot.subtitle = ggplot2::element_text(color = "#667085", size = 10.5),
      axis.text.x = ggplot2::element_text(color = "#344054", size = 10, margin = ggplot2::margin(b = 7)),
      axis.text.y = ggplot2::element_text(color = "#344054", size = 9.4, lineheight = 0.95),
      panel.grid.major.y = ggplot2::element_line(color = "#e5e7eb", linewidth = 0.35),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(10, 16, 12, 6)
    )

  size <- plot_svg_size(data.table::uniqueN(plot_dt$evidence_short), base_width = 10.8, base_height = 5.8, per_item = 0.34, max_height = 10)
  standard_girafe(p, size$width, size$height, hover_css = "stroke:#111827;stroke-width:1.8px;")
}

make_latest_bar_plot <- function(dt, title = "Latest values", value_col = "value", value_label = "Latest value", top_n = 10) {
  data.table::setDT(dt)
  if (nrow(dt) == 0 || !value_col %in% names(dt)) {
    return(empty_girafe("No data available"))
  }

  plot_dt <- copy(dt)[!is.na(get(value_col))]
  if (nrow(plot_dt) == 0) {
    return(empty_girafe("No values available"))
  }

  plot_dt[, plot_value := get(value_col)]
  plot_dt <- plot_dt[order(abs(plot_value))]
  plot_dt <- plot_dt[max(1, .N - top_n + 1):.N]
  plot_dt[, label_short := wrap_short(indicator_label, width = 26, max_chars = 58)]
  plot_dt[, label := factor(label_short, levels = label_short)]
  if (!"indicator_type" %in% names(plot_dt)) {
    plot_dt[, indicator_type := NA_character_]
  }
  if (!"precision" %in% names(plot_dt)) {
    plot_dt[, precision := NA_real_]
  }
  if (!"value_unit" %in% names(plot_dt)) {
    plot_dt[, value_unit := infer_indicator_unit(indicator, indicator_id, indicator_type)]
  }
  for (column in c("baseline_value", "change_from_baseline", "pct_change_from_baseline", "progress_pct_from_baseline")) {
    if (!column %in% names(plot_dt)) {
      plot_dt[, (column) := NA_real_]
    }
  }
  plot_dt[, positive_change := plot_value >= 0]
  plot_dt[, tooltip := paste0(
    indicator,
    "\nYear: ", survey_year,
    "\nLatest value: ", format_value_with_unit(value, precision, value_unit),
    ifelse(!is.na(baseline_value), paste0("\nBaseline: ", format_value_with_unit(baseline_value, precision, value_unit)), ""),
    ifelse(!is.na(change_from_baseline), paste0("\nNative-unit change: ", format_change(change_from_baseline, 1)), ""),
    ifelse("pct_change_from_baseline" %in% names(plot_dt) & !is.na(pct_change_from_baseline), paste0("\nPercent change: ", format_change(pct_change_from_baseline, 1), "%"), ""),
    ifelse("progress_pct_from_baseline" %in% names(plot_dt) & !is.na(progress_pct_from_baseline), paste0("\nDirection-adjusted progress: ", format_change(progress_pct_from_baseline, 1), "%"), "")
  )]

  p <- ggplot2::ggplot(plot_dt, ggplot2::aes(x = label, y = plot_value)) +
    ggplot2::geom_hline(yintercept = 0, color = "#d0d5dd", linewidth = 0.45) +
    ggiraph::geom_segment_interactive(
      ggplot2::aes(xend = label, y = 0, yend = plot_value, tooltip = tooltip, data_id = paste0(indicator_id, "-stem")),
      linewidth = 1.45,
      color = "#cbd5e1",
      lineend = "round"
    ) +
    ggiraph::geom_point_interactive(
      ggplot2::aes(tooltip = tooltip, data_id = indicator_id, fill = positive_change),
      shape = 21,
      color = "#ffffff",
      stroke = 0.45,
      size = 3.8
    ) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "#007c89", `FALSE` = "#bc5090"), guide = "none") +
    ggplot2::coord_flip(clip = "off") +
    ggplot2::labs(title = title, x = NULL, y = value_label) +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", color = "#132f2f", size = 14.5),
      axis.text.y = ggplot2::element_text(size = 10.4, lineheight = 0.98, color = "#344054"),
      axis.text.x = ggplot2::element_text(size = 10.5, color = "#344054"),
      axis.title.x = ggplot2::element_text(size = 11.5, color = "#667085"),
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(color = "#e5e7eb", linewidth = 0.35),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(10, 18, 10, 4)
    )

  size <- plot_svg_size(nrow(plot_dt), base_width = 8.2, base_height = 4.9, per_item = 0.48, max_height = 9.8)
  standard_girafe(p, size$width, size$height, hover_css = "fill:#f2a541;stroke:#111827;stroke-width:1px;")
}

make_kenya_context_map <- function(counties, latest_row = NULL, title = "Kenya county reference map", county_values = NULL, selected_year = NA_real_) {
  if (is.null(counties) || nrow(counties) == 0) {
    return(empty_girafe("Kenya geography is not available"))
  }

  counties <- sf::st_as_sf(counties)
  counties$map_value <- NA_real_
  counties$map_tooltip <- paste0("County: ", counties$shapeName, "
No county estimate in this DHS extract")
  note <- "County outlines are shown for context; this indicator has no county estimates in the DHS extract."

  if (!is.null(county_values) && nrow(county_values) > 0) {
    value_dt <- data.table::copy(county_values)[!is.na(region_id) & !is.na(value)]
    value_dt[, region_key := normalise_region_key(region_id)]
    value_dt <- value_dt[!duplicated(region_key)]

    name_match <- match(normalise_region_key(counties$shapeName), value_dt$region_key)
    id_match <- match(normalise_region_key(counties$shapeID), value_dt$region_key)
    iso_match <- match(normalise_region_key(counties$shapeISO), value_dt$region_key)
    match_index <- ifelse(!is.na(name_match), name_match, ifelse(!is.na(id_match), id_match, iso_match))
    matched <- !is.na(match_index)

    counties$map_value[matched] <- value_dt$value[match_index[matched]]
    unit <- first_available(value_dt$value_unit)
    counties$map_tooltip[matched] <- paste0(
      "County: ", counties$shapeName[matched],
      "
Value: ", format_value_with_unit(value_dt$value[match_index[matched]], value_dt$precision[match_index[matched]], unit),
      "
Survey year: ", selected_year
    )

    note <- if (any(matched)) {
      paste0(sum(matched), " counties matched for ", selected_year, ". Hover for the estimate.")
    } else {
      "County values were supplied, but their region identifiers do not match the Kenya boundary file."
    }
  } else if (!is.null(latest_row) && nrow(latest_row) > 0) {
    row <- latest_row[1]
    unit <- if ("value_unit" %in% names(row)) row$value_unit else infer_indicator_unit(row$indicator, row$indicator_id, row$indicator_type)
    note <- paste0(
      "Latest national estimate: ",
      format_value_with_unit(row$value, row$precision, unit),
      " in ", row$survey_year,
      ". County values are not available."
    )
  }

  p <- ggplot2::ggplot(counties) +
    ggiraph::geom_sf_interactive(
      ggplot2::aes(fill = map_value, tooltip = map_tooltip, data_id = shapeID),
      color = "#ffffff",
      linewidth = 0.35
    ) +
    ggplot2::coord_sf(datum = NA) +
    ggplot2::labs(title = title, subtitle = note, fill = "Value") +
    ggplot2::theme_void(base_size = 13) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", color = "#132f2f", size = 14, margin = ggplot2::margin(b = 4)),
      plot.subtitle = ggplot2::element_text(color = "#667085", size = 10.5, lineheight = 1.08, margin = ggplot2::margin(b = 8)),
      legend.position = if (any(!is.na(counties$map_value))) "bottom" else "none",
      plot.margin = ggplot2::margin(10, 10, 10, 10)
    )

  if (any(!is.na(counties$map_value))) {
    p <- p + ggplot2::scale_fill_gradient(low = "#d8eeeb", high = "#007c89", na.value = "#edf2f4")
  } else {
    p <- p + ggplot2::scale_fill_gradient(low = "#edf7f6", high = "#edf7f6", na.value = "#edf7f6", guide = "none")
  }

  standard_girafe(p, width_svg = 6.8, height_svg = 6.2, hover_css = "fill:#f2a541;stroke:#132f2f;stroke-width:1px;")
}