repo_url <- "https://cloud.r-project.org"
options(repos = c(CRAN = repo_url))

token <- Sys.getenv("RS_CONNECT_TOKEN")
secret <- Sys.getenv("RS_CONNECT_SECRET")
if (!nzchar(token) || !nzchar(secret)) {
  stop("RS_CONNECT_TOKEN and RS_CONNECT_SECRET must be configured.", call. = FALSE)
}

rsconnect::setAccountInfo(
  name = "mmburu",
  token = token,
  secret = secret
)

rsconnect::deployApp(
  appDir = ".",
  appName = desc::desc_get_field("Package"),
  appTitle = "Kenya DHS Indicators",
  appFiles = c(
    "R",
    "inst",
    "data",
    "NAMESPACE",
    "DESCRIPTION",
    "app.R"
  ),
  account = "mmburu",
  server = "shinyapps.io",
  lint = FALSE,
  forceUpdate = TRUE,
  packageRepositoryResolution = "lax",
  dependencyResolution = "library"
)
