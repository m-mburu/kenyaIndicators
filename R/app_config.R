app_sys <- function(...) {
  installed_path <- system.file(..., package = "kenyaIndicators")
  if (nzchar(installed_path)) {
    return(installed_path)
  }
  file.path(getwd(), "inst", ...)
}