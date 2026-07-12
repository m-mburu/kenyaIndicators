#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#' @import shiny
#' @import data.table
#' @noRd
app_server <- function(input, output, session) {
  dhs <- app_dhs_indicators()
  catalogue <- app_indicator_catalogue()
  pins <- app_dashboard_pins()
  timeline <- app_dashboard_timeline()
  policy_mapping <- policy_evidence_map()
  policy_summary <- shiny::reactive({
    policy_evidence_summary(timeline, catalogue, policy_mapping)
  })

  policy_focus_value <- shiny::reactiveVal(NULL)

  session$onFlushed(function() {
    stories <- policy_mapping[, .(sdg_label = sdg_label[1]), by = sdg_id]
    shiny::updateSelectInput(
      session,
      "policy_sdg",
      choices = c("All curated DHS evidence" = "all", stats::setNames(stories$sdg_id, paste(stories$sdg_id, "-", stories$sdg_label))),
      selected = "all"
    )
    shiny::updateSelectInput(
      session,
      "catalogue_domain",
      choices = c("All", sort(unique(catalogue$domain_group))),
      selected = "All"
    )
  }, once = TRUE)


  default_indicator_id <- pins[order(pin_order)]$indicator_id[1]
  selected_indicator_value <- shiny::reactiveVal(default_indicator_id)
  indicator_themes <- sort(unique(catalogue$analysis_theme[!is.na(catalogue$analysis_theme)]))
  default_theme <- catalogue[indicator_id %in% default_indicator_id, analysis_theme][1]

  indicator_choices <- function(theme) {
    available <- catalogue[analysis_theme %in% theme][order(indicator)]
    stats::setNames(
      available$indicator_id,
      paste0(available$indicator, " [", available$indicator_id, "]")
    )
  }

  update_indicator_choices <- function(theme, selected) {
    shiny::updateSelectizeInput(
      session,
      "indicator_id",
      choices = indicator_choices(theme),
      selected = selected,
      server = TRUE
    )
  }

  session$onFlushed(function() {
    shiny::updateSelectInput(
      session,
      "indicator_theme",
      choices = indicator_themes,
      selected = default_theme
    )
    update_indicator_choices(default_theme, default_indicator_id)
  }, once = TRUE)

  year_filtered <- shiny::reactive({
    dhs
  })

  selected_indicator_id <- shiny::reactive({
    id <- selected_indicator_value()
    req(length(id) == 1L)
    req(nzchar(id))
    id
  })

  shiny::observeEvent(input$indicator_theme, {
    theme <- input$indicator_theme
    req(theme %in% indicator_themes)
    choices <- indicator_choices(theme)
    current_id <- selected_indicator_value()
    target_id <- if (current_id %in% unname(choices)) current_id else unname(choices)[1]
    update_indicator_choices(theme, target_id)
    selected_indicator_value(target_id)
  }, ignoreInit = TRUE)

  shiny::observeEvent(input$indicator_id, {
    req(input$indicator_id %in% catalogue$indicator_id)
    selected_indicator_value(input$indicator_id)
  }, ignoreInit = TRUE)

  sync_indicator_controls <- function(id) {
    selected_row <- catalogue[indicator_id %in% id][1]
    theme <- selected_row$analysis_theme
    shiny::updateSelectInput(session, "indicator_theme", selected = theme)
    update_indicator_choices(theme, id)
  }
  shiny::observeEvent(input$open_indicator_explorer, {
    shiny::updateNavbarPage(session, "main_nav", selected = "Explore indicators")
  }, ignoreInit = TRUE)

  selected_policy_sdg <- shiny::reactive({
    shiny::req(input$policy_sdg)
    input$policy_sdg
  })

  shiny::observeEvent(input$policy_sdg, {
    policy_focus_value(NULL)
  }, ignoreInit = TRUE)

  output$policy_zoom_control <- shiny::renderUI({
    if (!is.null(policy_focus_value())) {
      shiny::div(
        class = "ki-overview-actions",
        shiny::actionButton(
          "policy_zoom_out",
          shiny::tagList(shiny::icon("arrow-left"), "Back to all panels"),
          class = "ki-back-button"
        )
      )
    }
  })

  output$policy_trend <- ggiraph::renderGirafe({
    focus_id <- policy_focus_value()
    if (!is.null(focus_id)) {
      dt <- data.table::copy(timeline)[indicator_id %in% focus_id]
      dt[, plot_group := "National estimate"]
      return(make_trend_plot(dt, first_available(dt$indicator)))
    }

    selected_sdg <- selected_policy_sdg()
    hypothesis_ids <- if (identical(selected_sdg, "all")) {
      unique(policy_mapping$hypothesis_id)
    } else {
      policy_mapping[sdg_id == selected_sdg, hypothesis_id]
    }
    dt <- data.table::copy(timeline)[hypothesis_id %in% hypothesis_ids]
    plot_width <- session$clientData$output_policy_trend_width
    ncol <- overview_panel_columns(plot_width)
    make_long_run_signal_plot(
      dt,
      title = if (identical(selected_sdg, "all")) "Curated DHS evidence trends" else paste(selected_sdg, "DHS evidence trends"),
      top_n = 16L,
      ncol = ncol
    )
  })

  shiny::observeEvent(input$policy_trend_selected, {
    selected <- input$policy_trend_selected
    shiny::req(length(selected) > 0L)
    id <- selected[[length(selected)]]
    shiny::req(id %in% catalogue$indicator_id)
    selected_indicator_value(id)
    sync_indicator_controls(id)
    policy_focus_value(id)
  }, ignoreInit = TRUE)

  shiny::observeEvent(input$policy_zoom_out, {
    policy_focus_value(NULL)
  }, ignoreInit = TRUE)
  output$policy_kpis <- shiny::renderUI({
    summary <- policy_summary()
    shiny::div(
      class = "ki-kpi-grid",
      kpi_card("DHS-relevant SDGs", format_number(nrow(summary)), "curated policy areas"),
      kpi_card("Improving", format_number(summary[status == "Improving", .N]), "more improving than worsening measures"),
      kpi_card("Mixed or worsening", format_number(summary[status %in% c("Mixed", "Worsening"), .N]), "requires closer interpretation"),
      kpi_card("Evidence indicators", format_number(sum(summary$evidence_count)), "included in policy summaries")
    )
  })

  filtered_catalogue <- shiny::reactive({
    dt <- data.table::copy(catalogue)
    if (!is.null(input$catalogue_domain) && input$catalogue_domain != "All") {
      dt <- dt[domain_group == input$catalogue_domain]
    }
    if (identical(input$catalogue_quality, "Confidence intervals available")) dt <- dt[has_ci == TRUE]
    if (identical(input$catalogue_quality, "Denominator available")) dt <- dt[has_denominator == TRUE]
    if (identical(input$catalogue_quality, "Latest estimate is 2022")) dt <- dt[latest_year == 2022]
    dt
  })

  output$catalogue_table <- DT::renderDT({
    display <- filtered_catalogue()[, .(
      Domain = domain_group,
      Indicator = indicator,
      `Indicator ID` = indicator_id,
      Unit = value_unit,
      `Years available` = years_available,
      `Latest year` = latest_year,
      `Has CI` = has_ci,
      `Has denominator` = has_denominator,
      `County estimates` = county_available
    )]
    datatable_compact(display, 12, "460px")
  })

  output$download_catalogue <- shiny::downloadHandler(
    filename = function() paste0("kenya-dhs-indicator-catalogue-", Sys.Date(), ".csv"),
    content = function(file) data.table::fwrite(filtered_catalogue(), file)
  )

  output$evidence_gap_table <- DT::renderDT({
    datatable_compact(policy_evidence_gaps(), 12, "460px")
  })
  selected_indicator_data <- shiny::reactive({
    id <- selected_indicator_id()
    dt <- year_filtered()[indicator_id %in% id]
    preferred <- dt[preferred_total_flag == TRUE]
    if (uniqueN(preferred$survey_year) >= 2) {
      canonical_indicator_rows(
        preferred,
        by_cols = c(
          "indicator_id", "survey_year",
          "characteristic_label", "by_variable_label"
        )
      )
    } else {
      canonical_indicator_rows(
        dt,
        by_cols = c(
          "indicator_id", "survey_year",
          "characteristic_label", "by_variable_label"
        )
      )
    }
  })


  selected_indicator_plot_data <- shiny::reactive({
    id <- selected_indicator_id()
    selected_row <- catalogue[indicator_id %in% id][1]

    if (selected_row$sex_group %in% c("Women", "Men")) {
      family_ids <- catalogue[
        series_family %in% selected_row$series_family &
          sex_group %in% c("Women", "Men"),
        indicator_id
      ]

      if (data.table::uniqueN(family_ids) >= 2L) {
        comparison <- dhs[indicator_id %in% family_ids]
        preferred <- comparison[preferred_total_flag == TRUE]
        if (data.table::uniqueN(preferred$indicator_id) >= 2L) {
          comparison <- preferred
        } else {
          totals <- comparison[is_total == TRUE]
          if (nrow(totals) > 0) comparison <- totals
        }

        comparison <- canonical_indicator_rows(
          comparison,
          by_cols = c("indicator_id", "survey_year")
        )
        comparison[, plot_group := factor(sex_group, levels = c("Women", "Men"))]
        return(comparison)
      }
    }

    selected_indicator_data()
  })

  output$indicator_header <- shiny::renderUI({
    id <- selected_indicator_id()
    row <- catalogue[indicator_id %in% id][1]
    comparison <- if (row$sex_group %in% c("Women", "Men")) {
      "Women and men are shown together when both published series are available."
    } else {
      "The chart shows the preferred published national series."
    }

    shiny::div(
      class = "ki-indicator-summary",
      shiny::h3(row$indicator),
      shiny::div(
        class = "ki-indicator-facts",
        shiny::span(shiny::strong("Theme"), row$analysis_theme),
        shiny::span(shiny::strong("Unit"), row$value_axis_label),
        shiny::span(shiny::strong("Years"), paste(row$min_year, row$latest_year, sep = "-")),
        shiny::span(shiny::strong("Survey waves"), format_number(row$year_count))
      ),
      shiny::p(comparison),
      shiny::p(class = "ki-indicator-source", paste0("Indicator ID: ", row$indicator_id, " | Source: ", row$resource_name))
    )
  })
  output$indicator_trend <- ggiraph::renderGirafe({
    dt <- selected_indicator_plot_data()
    if (!"plot_group" %in% names(dt)) {
      dt[, plot_group := fifelse(!is.na(by_variable_label) & nzchar(by_variable_label), by_variable_label, characteristic_label)]
      dt[is.na(plot_group) | !nzchar(plot_group), plot_group := "Total"]
    }

    id <- selected_indicator_id()
    row <- catalogue[indicator_id %in% id][1]
    title <- if (data.table::uniqueN(dt$plot_group) > 1 && row$sex_group %in% c("Women", "Men")) {
      paste0(gsub("^(Women|Men) ", "", row$indicator), " by sex")
    } else {
      row$indicator
    }
    make_trend_plot(dt, title)
  })


  output$quality_kpis <- shiny::renderUI({
    shiny::div(
      class = "ki-kpi-grid",
      kpi_card("Sparse indicators", format_number(catalogue[year_count <= 2, .N]), "two or fewer survey years"),
      kpi_card("With CI", format_number(catalogue[has_ci == TRUE, .N]), "resource-indicator pairs"),
      kpi_card("With denominator", format_number(catalogue[has_denominator == TRUE, .N]), "resource-indicator pairs"),
      kpi_card("Latest is 2022", format_number(catalogue[latest_year == 2022, .N]), "resource-indicator pairs")
    )
  })

  output$quality_table <- DT::renderDT({
    display <- catalogue[, .(
      Domain = domain_group,
      Resource = resource_name,
      Indicator = indicator,
      `Years available` = years_available,
      `Year count` = year_count,
      `Latest year` = latest_year,
      `Has CI` = has_ci,
      `Has denominator` = has_denominator,
      Sparse = year_count <= 2
    )]
    datatable_compact(display, 12, "420px")
  })
}
