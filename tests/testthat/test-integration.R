test_that("snapshot works in sandbox (testing mode)", {
  skip_if_not_installed("withr")
  
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  # Create test data
  dir.create(file.path(temp_project, "data"))
  test_data <- data.frame(x = 1:10, y = rnorm(10, mean = 5, sd = 1))
  saveRDS(test_data, file.path(temp_project, "data", "input.rds"))
  
  # Create analysis script with snapshot
  script_content <- '
data <- readRDS("data/input.rds")
model <- lm(y ~ x, data = data)
snapshot(model, "test_model", script_name = "analysis")
saveRDS(model, "model.rds")
'
  script_path <- file.path(temp_project, "analysis.R")
  writeLines(script_content, script_path)
  
  on.exit(unlink(temp_project, recursive = TRUE), add = TRUE)
  
  # Change to project directory
  old_wd <- getwd()
  setwd(temp_project)
  on.exit(setwd(old_wd), add = TRUE)
  
  # Step 1: Run interactively to create snapshot
  data <- readRDS("data/input.rds")
  model <- lm(y ~ x, data = data)
  snapshot(model, "test_model", script_name = "analysis")
  
  snapshot_file <- file.path(temp_project, "_resultcheck_snapshots", "analysis", "test_model.md")
  expect_true(file.exists(snapshot_file))
  expect_equal(tools::file_ext(snapshot_file), "md")
  
  # Step 2: Run in sandbox with same data (should pass)
  sandbox <- setup_sandbox(c("data/input.rds"))
  expect_silent(run_in_sandbox(script_path, sandbox))
  cleanup_sandbox(sandbox)
  
  # Step 3: Change data and run in sandbox (should error)
  different_data <- data.frame(x = 1:10, y = rnorm(10, mean = 8, sd = 1))
  saveRDS(different_data, file.path(temp_project, "data", "input.rds"))
  
  sandbox <- setup_sandbox(c("data/input.rds"))
  expect_error(
    run_in_sandbox(script_path, sandbox),
    "Snapshot differences found"
  )
  cleanup_sandbox(sandbox)
})
