test_that("run_app is exported", {
  expect_true(is.function(run_app))
})

test_that("overview columns respond to logical plot width", {
  expect_identical(overview_panel_columns(NULL), 2L)
  expect_identical(overview_panel_columns(999), 2L)
  expect_identical(overview_panel_columns(1000), 3L)
  expect_identical(overview_panel_columns(1599), 3L)
  expect_identical(overview_panel_columns(1600), 4L)
})

test_that("policy overview zooms into a selected trend and resets", {
  shiny::testServer(app_server, {
    session$flushReact()
    selected_id <- app_dashboard_timeline()$indicator_id[1]

    session$setInputs(policy_trend_selected = selected_id)
    session$flushReact()

    expect_identical(policy_focus_value(), selected_id)
    expect_identical(selected_indicator_id(), selected_id)
    expect_silent(output$policy_trend)
    expect_true(any(grepl("Back to all panels", as.character(output$policy_zoom_control), fixed = TRUE)))

    session$setInputs(policy_zoom_out = 1)
    session$flushReact()
    expect_null(policy_focus_value())
  })
})
test_that("navigation is task-oriented and the overview stays visual", {
  ui_text <- paste(as.character(app_ui(NULL)), collapse = " ")

  expect_match(ui_text, "Overview", fixed = TRUE)
  expect_match(ui_text, "Explore indicators", fixed = TRUE)
  expect_match(ui_text, "Evidence coverage", fixed = TRUE)
  expect_match(ui_text, "Explore all indicators", fixed = TRUE)
  expect_false(grepl("Compare SDG evidence", ui_text, fixed = TRUE))
  expect_false(grepl("indicator_metadata", ui_text, fixed = TRUE))
  expect_false(grepl("kenya_map", ui_text, fixed = TRUE))
  expect_false(grepl("indicator_rows", ui_text, fixed = TRUE))
  expect_false(grepl("policy_status", ui_text, fixed = TRUE))
})
test_that("minimal indicator explorer renders its summary and chart", {
  shiny::testServer(app_server, {
    session$flushReact()
    expect_silent(output$indicator_header)
    expect_silent(output$indicator_trend)
  })
})