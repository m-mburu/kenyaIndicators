#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#' @import shiny
#' @importFrom DT DTOutput
#' @importFrom ggiraph girafeOutput
#' @importFrom shinycssloaders withSpinner
#' @noRd

plot_panel <- function(title, output, class = "") {
  shiny::div(class = paste("ki-panel", class), shiny::div(class = "ki-panel-head", shiny::h4(title)), output)
}

section_head <- function(kicker, title, copy = NULL) {
  shiny::div(class = "ki-section-head", shiny::div(class = "ki-eyebrow", kicker), shiny::h2(title), if (!is.null(copy)) shiny::p(copy))
}

indicator_controls <- function() {
  shiny::div(
    class = "ki-explorer-controls",
    shiny::fluidRow(
      shiny::column(3, shiny::selectInput("indicator_theme", "Theme", choices = NULL)),
      shiny::column(9, shiny::selectizeInput("indicator_id", "Indicator", choices = NULL, options = list(placeholder = "Choose an indicator")))
    )
  )
}

evidence_header <- function() {
  shiny::div(class = "ki-overview-head", shiny::div(class = "ki-eyebrow", "National health survey"), shiny::h1("Kenya DHS trend analysis"), shiny::p("Explore long-run changes in fertility, child survival, health services, WASH, HIV, malaria, education, and agency."))
}

app_ui <- function(request) {
  shiny::tagList(
    golem_add_external_resources(),
    shiny::navbarPage(
      title = "Kenya DHS", id = "main_nav",
      shiny::tabPanel(
        "Overview",
        shiny::fluidPage(shiny::div(
          class = "ki-page",
          section_head("Policy evidence", "Kenya's DHS evidence for SDG progress", "Scan trends; hover or focus for the latest value and select for details. Use the filters to focus on an SDG theme or status."),
          shiny::fluidRow(
            shiny::column(6, shiny::selectInput("policy_sdg", "Filter overview", choices = NULL)),
            shiny::column(
              6,
              shiny::div(
                class = "ki-overview-explore",
                shiny::actionButton(
                  "open_indicator_explorer",
                  shiny::tagList(shiny::icon("magnifying-glass"), "Explore all indicators"),
                  class = "ki-explore-button"
                )
              )
            )
          ),
          shiny::uiOutput("policy_kpis"),
          shiny::fluidRow(shiny::column(12, shiny::uiOutput("policy_zoom_control"))),
          shiny::fluidRow(shiny::column(12, shiny::uiOutput("policy_detail"))),
          shiny::div(
            class = "ki-overview-scale-note",
            shiny::strong("Independent scales."),
            " Compare direction, not slope or magnitude."
          ),
          shiny::fluidRow(shiny::column(12, plot_panel("DHS evidence trends", shinycssloaders::withSpinner(ggiraph::girafeOutput("policy_trend"), color = "#007c89"), "ki-panel-story")))
        ))
      ),
      shiny::tabPanel(
        "Explore indicators",
        shiny::fluidPage(shiny::div(
          class = "ki-page ki-explorer-page",
          section_head("Indicator explorer", "Explore all DHS indicators", "Choose a theme and indicator, then read its published national trend in the original unit."),
          indicator_controls(),
          shiny::uiOutput("indicator_header"),
          shiny::fluidRow(
            shiny::column(
              12,
              plot_panel(
                "Trend over survey years",
                shinycssloaders::withSpinner(ggiraph::girafeOutput("indicator_trend"), color = "#007c89"),
                "ki-panel-focus"
              )
            )
          )
        ))
      ),
      shiny::tabPanel(
        "Evidence coverage",
        shiny::fluidPage(shiny::div(
          class = "ki-page",
          section_head("Evidence system", "Understand what the DHS evidence can support", "Review coverage quality, inspect the underlying catalogue, and identify questions that require companion data."),
          shiny::tabsetPanel(
            id = "coverage_tabs",
            type = "tabs",
            shiny::tabPanel(
              "Coverage quality",
              shiny::div(
                class = "ki-local-view",
                section_head("Evidence confidence", "Separate stable trends from sparse signals", "Quality flags show repeated survey years, confidence intervals, denominators, and latest-year coverage."),
                shiny::uiOutput("quality_kpis"),
                plot_panel("Quality and coverage flags", shinycssloaders::withSpinner(DT::DTOutput("quality_table"), color = "#007c89"))
              )
            ),
            shiny::tabPanel(
              "Indicator catalogue",
              shiny::div(
                class = "ki-local-view",
                section_head("Indicator inventory", "Find the evidence behind the analysis", "Filter by domain and evidence availability, then export the resulting records."),
                shiny::fluidRow(
                  shiny::column(4, shiny::selectInput("catalogue_domain", "Domain", choices = NULL)),
                  shiny::column(4, shiny::selectInput("catalogue_quality", "Evidence availability", choices = c("All", "Confidence intervals available", "Denominator available", "Latest estimate is 2022"))),
                  shiny::column(4, shiny::br(), shiny::downloadButton("download_catalogue", "Download filtered CSV", class = "btn-primary"))
                ),
                plot_panel("Indicators", shinycssloaders::withSpinner(DT::DTOutput("catalogue_table"), color = "#007c89"))
              )
            ),
            shiny::tabPanel(
              "Evidence gaps",
              shiny::div(
                class = "ki-local-view",
                section_head("Scope boundary", "Questions DHS cannot answer alone", "These gaps prevent household-survey evidence from being presented as a complete measure of national SDG progress."),
                plot_panel("Required companion data", DT::DTOutput("evidence_gap_table"))
              )
            )
          )
        ))
      )
    )
  )
}

#' Add external Resources to the Application
#' @importFrom shiny HTML tags
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  golem::add_resource_path("www", app_sys("app/www"))
  shiny::tags$head(
    golem::favicon(),
    golem::bundle_resources(
      path = app_sys("app/www"),
      app_title = "kenyaIndicators"
    ),
    shiny::tags$script(
      async = NA,
      src = paste0(
        "https://www.googletagmanager.com/gtag/js?id=",
        "G-BFNZ97VTLJ"
      )
    ),
    shiny::tags$script(
      shiny::HTML(
        paste(
          "window.dataLayer = window.dataLayer || [];",
          "function gtag(){dataLayer.push(arguments);}",
          "gtag('js', new Date());",
          "gtag('config', 'G-BFNZ97VTLJ');",
          sep = "\n"
        )
      )
    )
  )
}
