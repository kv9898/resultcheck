test_that("sandbox and snapshot integration works", {
  skip_if_not_installed("withr")
  
  # Create a temporary project with .git marker
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  # Create test data file in project
  dir.create(file.path(temp_project, "data"))
  test_data <- data.frame(x = 1:10, y = rnorm(10, mean = 5, sd = 1))
  saveRDS(test_data, file.path(temp_project, "data", "input.rds"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  # Work within the project directory
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(temp_project)
  
  # Create analysis script
  script_content <- '
# Load data
data <- readRDS("data/input.rds")

# Create model
model <- lm(y ~ x, data = data)

# Save model for testing
saveRDS(model, "model.rds")
'
  script_path <- file.path(temp_project, "analysis.R")
  writeLines(script_content, script_path)
  
  # Create sandbox and run script (use absolute path)
  sandbox <- setup_sandbox(c("data/input.rds"))
  run_in_sandbox(script_path, sandbox)
  
  # Load the model from sandbox
  model <- readRDS(file.path(sandbox$path, "model.rds"))
  
  # Create initial snapshot
  snapshot(model, "test_model", script_name = "integration_test", interactive = FALSE)
  
  # Verify snapshot was created
  snapshot_file <- file.path(temp_project, "_resultcheck_snapshots", 
                             "integration_test", "test_model.rds")
  expect_true(file.exists(snapshot_file))
  
  # Run again and verify snapshot matches
  cleanup_sandbox(sandbox)
  sandbox <- setup_sandbox(c("data/input.rds"))
  run_in_sandbox(script_path, sandbox)
  model2 <- readRDS(file.path(sandbox$path, "model.rds"))
  
  # Use expect_snapshot_value
  expect_snapshot_value(model2, "test_model", script_name = "integration_test")
  
  # Cleanup
  cleanup_sandbox(sandbox)
})
