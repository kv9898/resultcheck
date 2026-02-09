# Example: Interactive Snapshotting Workflow
# This demonstrates how to use the snapshot functionality

library(resultcheck)

# First, let's check our project root
root <- find_root()
cat("Project root:", root, "\n\n")

# Example 1: Basic snapshot usage
# --------------------------------
cat("Example 1: Creating a snapshot\n")
cat("-------------------------------\n")

# Create some analysis output
data <- data.frame(
  x = 1:10,
  y = rnorm(10, mean = 5, sd = 2)
)

model <- lm(y ~ x, data = data)

# Save snapshot (first time creates it)
snapshot(model, "linear_model", script_name = "snapshot_examples", interactive = FALSE)

# Try snapshotting again with same value (should match)
snapshot(model, "linear_model", script_name = "snapshot_examples", interactive = FALSE)

cat("\n")

# Example 2: Detecting changes
# -----------------------------
cat("Example 2: Detecting changes\n")
cat("-----------------------------\n")

# Create initial snapshot
original_summary <- data.frame(
  variable = c("intercept", "slope"),
  estimate = c(1.5, 0.8),
  p_value = c(0.001, 0.05)
)

snapshot(original_summary, "model_summary", script_name = "snapshot_examples", interactive = FALSE)

# Modify the data
modified_summary <- data.frame(
  variable = c("intercept", "slope"),
  estimate = c(1.5, 0.9),  # Changed slope!
  p_value = c(0.001, 0.03)  # Changed p-value!
)

# This will detect differences
snapshot(modified_summary, "model_summary", script_name = "snapshot_examples", interactive = FALSE)

cat("\n")

# Example 3: Snapshots with different object types
# -------------------------------------------------
cat("Example 3: Different object types\n")
cat("----------------------------------\n")

# Snapshot a list
config <- list(
  model_type = "linear",
  covariates = c("age", "income", "education"),
  n_iterations = 1000
)
snapshot(config, "analysis_config", script_name = "snapshot_examples", interactive = FALSE)

# Snapshot a vector
coefficients <- c(intercept = 2.5, age = 0.3, income = 0.05)
snapshot(coefficients, "coefficients", script_name = "snapshot_examples", interactive = FALSE)

# Snapshot a data frame
results_table <- data.frame(
  term = c("intercept", "age", "income"),
  estimate = c(2.5, 0.3, 0.05),
  std_error = c(0.1, 0.02, 0.01),
  p_value = c(0.001, 0.01, 0.001)
)
snapshot(results_table, "results_table", script_name = "snapshot_examples", interactive = FALSE)

cat("\n")

# Example 4: Organizing snapshots by script
# ------------------------------------------
cat("Example 4: Organization by script\n")
cat("----------------------------------\n")

# Snapshots for different scripts are kept separate
snapshot(data.frame(a = 1:3), "data_a", script_name = "script1", interactive = FALSE)
snapshot(data.frame(b = 4:6), "data_b", script_name = "script2", interactive = FALSE)

# Check the directory structure
snapshot_dir <- file.path(root, "_resultcheck_snapshots")
if (dir.exists(snapshot_dir)) {
  cat("Snapshot directory structure:\n")
  cat("_resultcheck_snapshots/\n")
  scripts <- list.dirs(snapshot_dir, full.names = FALSE, recursive = FALSE)
  for (script in scripts) {
    cat("  ", script, "/\n", sep = "")
    files <- list.files(file.path(snapshot_dir, script))
    for (file in files) {
      cat("    ", file, "\n", sep = "")
    }
  }
}

cat("\n")

# Example 5: Using with testthat
# -------------------------------
cat("Example 5: Integration with testthat\n")
cat("-------------------------------------\n")

library(testthat)

# First create the snapshot interactively
test_data <- data.frame(x = 1:5, y = 6:10)
snapshot(test_data, "test_data", script_name = "example_tests", interactive = FALSE)

# Then in your test, use expect_snapshot_value
test_that("data snapshot matches", {
  # Recreate the same data
  test_data <- data.frame(x = 1:5, y = 6:10)
  
  # This should pass
  expect_snapshot_value(test_data, "test_data", script_name = "example_tests")
})

cat("\nTest passed! Snapshot matches.\n")

cat("\n")
cat("Examples complete!\n")
cat("Snapshot files are stored in: ", file.path(root, "_resultcheck_snapshots"), "\n")
