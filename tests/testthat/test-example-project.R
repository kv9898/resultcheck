# Integrated example: demonstrates the full resultcheck workflow with a
# realistic project containing data/income.csv, analysis.R, and a test.
#
# The example files live in inst/extdata/ and are copied into a temporary
# project directory so the test is fully self-contained.

test_that("example project: analysis produces stable results", {
  skip_if_not_installed("withr")

  # ----- build a temporary project that mirrors a real user project ----------
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, "data"))
  dir.create(file.path(temp_project, ".git"))  # acts as project-root marker
  on.exit(unlink(temp_project, recursive = TRUE), add = TRUE)

  # Copy example files from the package
  example_dir <- system.file("extdata", package = "resultcheck")
  file.copy(
    file.path(example_dir, "data", "income.csv"),
    file.path(temp_project, "data", "income.csv")
  )
  file.copy(
    file.path(example_dir, "analysis.R"),
    file.path(temp_project, "analysis.R")
  )

  withr::local_dir(temp_project)

  # ----- Step 1: simulate interactive run to create reference snapshot -------
  data <- read.csv("data/income.csv")
  model <- lm(income ~ age + education, data = data)
  snapshot(model, "income_model", script_name = "analysis")

  snapshot_file <- file.path(
    temp_project, "tests/_resultcheck_snaps", "analysis", "income_model.md"
  )
  expect_true(file.exists(snapshot_file))

  # ----- Step 2: run analysis in an isolated sandbox ------------------------
  # Only input data is copied; snapshot files are NOT passed (they live at the
  # project root and are located automatically by find_root()).
  sandbox <- setup_sandbox("data/income.csv")
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  # Errors if snapshot is missing or doesn't match
  expect_no_error(run_in_sandbox("analysis.R", sandbox))

  # ----- Step 3: verify output files were written by the analysis -----------
  expect_true(
    file.exists(file.path(sandbox$path, "output", "model_summary.csv"))
  )
})


test_that("example project: passing a whole directory to setup_sandbox works", {
  skip_if_not_installed("withr")

  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, "data"))
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE), add = TRUE)

  example_dir <- system.file("extdata", package = "resultcheck")
  file.copy(
    file.path(example_dir, "data", "income.csv"),
    file.path(temp_project, "data", "income.csv")
  )
  file.copy(
    file.path(example_dir, "analysis.R"),
    file.path(temp_project, "analysis.R")
  )

  withr::local_dir(temp_project)

  # Create reference snapshot
  data <- read.csv("data/income.csv")
  model <- lm(income ~ age + education, data = data)
  snapshot(model, "income_model", script_name = "analysis")

  # Pass the entire data/ directory instead of listing individual files
  sandbox <- setup_sandbox("data")
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  expect_true(file.exists(file.path(sandbox$path, "data", "income.csv")))
  expect_no_error(run_in_sandbox("analysis.R", sandbox))
  expect_true(
    file.exists(file.path(sandbox$path, "output", "model_summary.csv"))
  )
})
