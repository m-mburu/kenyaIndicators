repo_url <- "https://cloud.r-project.org"
options(repos = c(RSPM = repo_url, CRAN = repo_url))
Sys.setenv(
  RSPM = repo_url,
  RENV_CONFIG_REPOS_OVERRIDE = paste0(
    "RSPM=", repo_url, ";CRAN=", repo_url
  )
)

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

deploy_args <- list(
  appDir = ".",
  appName = desc::desc_get_field("Package"),
  appTitle = "Kenya DHS Indicators",
  appFiles = c(
    "R",
    "inst",
    "data",
    "NAMESPACE",
    "DESCRIPTION",
    "renv.lock",
    "app.R"
  ),
  account = "mmburu",
  server = "shinyapps.io",
  lint = FALSE,
  forceUpdate = TRUE
)

# rsconnect versions expose repository and dependency resolution controls
# through optional arguments. Use the lockfile whenever those controls exist.
optional_deploy_args <- list(
  packageRepositoryResolutionR = "lax",
  dependencyResolution = "strict"
)
supported_args <- intersect(
  names(optional_deploy_args),
  names(formals(rsconnect::deployApp))
)
deploy_args[supported_args] <- optional_deploy_args[supported_args]

do.call(rsconnect::deployApp, deploy_args)
