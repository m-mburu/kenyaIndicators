test_that("policy evidence map covers the implemented story tabs", {
  mapping <- policy_evidence_map()

  expect_setequal(unique(mapping$sdg_id), c("SDG 3", "SDG 4", "SDG 5", "SDG 6"))
  expect_equal(anyDuplicated(mapping[, .(sdg_id, hypothesis_id)]), 0L)
})

test_that("policy summary uses only curated latest evidence", {
  summary <- policy_evidence_summary(app_dashboard_timeline(), app_indicator_catalogue())

  expect_equal(nrow(summary), 4L)
  expect_true(all(summary$evidence_count > 0L))
  expect_true(all(summary$status %in% c("Improving", "Mixed", "Worsening", "Insufficient evidence")))
  expect_true(all(summary$latest_year <= 2022))
})

test_that("story rows are scoped to the selected SDG", {
  mapping <- policy_evidence_map()
  health <- policy_story_rows(app_dashboard_timeline(), app_indicator_catalogue(), "SDG 3", mapping)
  wash <- policy_story_rows(app_dashboard_timeline(), app_indicator_catalogue(), "SDG 6", mapping)

  expect_true(nrow(health) > 0L)
  expect_true(nrow(wash) > 0L)
  expect_false(any(health$hypothesis_id %in% mapping[sdg_id == "SDG 6", hypothesis_id]))
})
test_that("indexed story charts use stable indicator IDs", {
  timeline <- app_dashboard_timeline()
  expect_false("data_id" %in% names(timeline))
  expect_match(
    paste(deparse(body(make_indexed_trend_plot)), collapse = "\n"),
    "data_id = paste\\(indicator_id, survey_year, plot_group"
  )
})
