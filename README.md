# resultcheck

Result Stability Checks for Empirical R Projects

## Overview

`resultcheck` provides lightweight helpers for checking whether empirical results remain substantively unchanged across code revisions, platform differences, and package updates. The package supports regression-style testing of derived datasets, statistical model outputs, tables, and plots, helping researchers detect unintended result drift early and distinguish material from non-material changes in empirical workflows.

## Installation

You can install the development version of resultcheck from GitHub:

```r
# install.packages("devtools")
devtools::install_github("kv9898/resultcheck")
```

## Sandboxing Functions

The package provides three core functions for sandboxing empirical analysis scripts during testing:

### `setup_sandbox()`

Creates a temporary directory and copies specified files while preserving their directory structure. This is useful for testing empirical analysis scripts in isolation.

```r
# Create sandbox and copy required files
sandbox <- setup_sandbox(c(
  "data/panel_data_pca.rds",
  "data/fiscal.dta",
  "save/regModels.RData",
  "helper/f_test_fiscal.R"
))

# Access sandbox path
print(sandbox$path)
# [1] "/tmp/RtmpXXXX/sandbox_20240208_123456_a1b2c3d4"
```

**Parameters:**
- `files`: Character vector of file paths to copy to the sandbox
- `temp_base`: Optional custom location for the temporary directory (defaults to `tempfile()`)

**Returns:** A sandbox object containing:
- `path`: The path to the created temporary directory
- `id`: A unique timestamp-based identifier for this sandbox

### `run_in_sandbox()`

Executes an R script within a sandbox directory, suppressing messages, warnings, and graphical output.

```r
# Run script in the sandbox
run_in_sandbox("code/fiscal.R", sandbox)

# Or use the most recently created sandbox
run_in_sandbox("code/fiscal.R")
```

**Parameters:**
- `script_path`: Path to the R script to execute
- `sandbox`: Optional sandbox object (defaults to most recently created sandbox)
- `suppress_messages`: Whether to suppress messages (default: TRUE)
- `suppress_warnings`: Whether to suppress warnings (default: TRUE)
- `capture_output`: Whether to capture output (default: TRUE)

### `cleanup_sandbox()`

Removes a sandbox directory and all its contents.

```r
# Clean up when done
cleanup_sandbox(sandbox)

# Or clean up the most recently created sandbox
cleanup_sandbox()
```

**Parameters:**
- `sandbox`: Optional sandbox object (defaults to most recently created sandbox)
- `force`: Whether to force removal even if directory contains files (default: TRUE)

## Complete Example

Here's a complete example of using the sandboxing functions in a test:

```r
library(testthat)
library(resultcheck)

test_that("fiscal script produces reproducible results", {
  # Setup: Create sandbox and copy required files
  sandbox <- setup_sandbox(c(
    "data/panel_data_pca.rds",
    "data/fiscal.dta",
    "save/regModels.RData",
    "helper/f_test_fiscal.R"
  ))
  
  # Run the analysis script in the sandbox
  run_in_sandbox("code/fiscal.R", sandbox)
  
  # Test: Check that expected outputs were created
  expect_true(file.exists(file.path(sandbox$path, "data/panel_data_fiscal.rds")))
  expect_true(file.exists(file.path(sandbox$path, "save/regModels_fiscal.RData")))
  expect_true(file.exists(file.path(sandbox$path, "save/regTable_fiscal.RData")))
  
  # Compare with original outputs
  original_data <- readRDS("data/panel_data_fiscal.rds")
  regenerated_data <- readRDS(file.path(sandbox$path, "data/panel_data_fiscal.rds"))
  
  expect_equal(dim(original_data), dim(regenerated_data))
  expect_equal(names(original_data), names(regenerated_data))
  
  # Cleanup: Remove sandbox
  cleanup_sandbox(sandbox)
})
```

## Interactive Snapshotting

The package provides interactive snapshotting functionality for empirical researchers who want to track changes in their analysis outputs without manually saving and comparing files.

### `snapshot()`

Creates or updates a snapshot of an R object during interactive analysis. On first use, it saves the object. On subsequent uses, it compares the current object to the saved snapshot and prompts you to update if differences are found.

```r
# In your analysis script:
model <- lm(mpg ~ wt + hp, data = mtcars)

# First time: saves the snapshot
snapshot(model, "mtcars_regression")
# Message: New snapshot saved: interactive/mtcars_regression.rds

# Later, if the model changes:
model <- lm(mpg ~ wt + hp + cyl, data = mtcars)
snapshot(model, "mtcars_regression")
# Shows differences and prompts: Update snapshot? (y/n):
```

**How it works:**

1. Snapshots are stored in `_resultcheck_snapshots/` directory at your project root
2. Files are organized by script name (auto-detected or specified)
3. On first call, the snapshot is saved
4. On subsequent calls, differences are shown using human-readable comparisons
5. You're prompted to update the snapshot if changes are detected

**Parameters:**
- `value`: The R object to snapshot (data frame, model, list, etc.)
- `name`: A descriptive name for the snapshot
- `script_name`: Optional script name (auto-detected if not provided)
- `interactive`: Whether to prompt for updates (default: TRUE)

### `expect_snapshot_value()`

Use snapshots in automated tests with testthat:

```r
library(testthat)
library(resultcheck)

test_that("regression model is stable", {
  model <- lm(mpg ~ wt + hp, data = mtcars)
  
  # Compare against saved snapshot
  expect_snapshot_value(model, "mtcars_regression", script_name = "test-models")
})
```

**Workflow:**

1. Run your analysis script interactively and use `snapshot()` to save outputs
2. In tests, use `expect_snapshot_value()` to verify outputs match the snapshots
3. If outputs change, re-run interactively to review and update snapshots

### `find_root()`

Finds your project root directory using these markers (in order):
- `resultcheck.yml` configuration file
- `.Rproj` file
- `.git` directory

```r
root <- find_root()
print(root)
# [1] "/path/to/your/project"
```

This ensures snapshots are stored consistently regardless of your current working directory.

## Complete Example with Snapshots

Here's a complete workflow combining sandboxing and snapshotting:

```r
library(resultcheck)

# Interactive analysis (analysis.R)
# ----------------------------------
data <- readRDS("data/survey_data.rds")
model <- lm(satisfaction ~ age + income, data = data)

# Save snapshot interactively
snapshot(model, "satisfaction_model")
snapshot(summary(model)$coefficients, "model_coefficients")

# Automated test (test-analysis.R)
# ---------------------------------
library(testthat)

test_that("satisfaction model produces consistent results", {
  # Setup sandbox
  sandbox <- setup_sandbox(c("data/survey_data.rds"))
  
  # Run analysis in sandbox
  run_in_sandbox("analysis.R", sandbox)
  
  # Load results from sandbox
  # (assuming analysis.R saves the model)
  model_path <- file.path(sandbox$path, "model.rds")
  model <- readRDS(model_path)
  
  # Compare against snapshot
  expect_snapshot_value(model, "satisfaction_model", script_name = "analysis")
  
  # Cleanup
  cleanup_sandbox(sandbox)
})
```

## Using with testthat

The sandboxing functions integrate seamlessly with `testthat`. The most recently created sandbox is automatically tracked, so you can omit the `sandbox` parameter in `run_in_sandbox()` and `cleanup_sandbox()`:

```r
test_that("analysis workflow", {
  # Create sandbox
  sandbox <- setup_sandbox(c("data/mydata.rds"))
  
  # Run without explicitly passing sandbox
  run_in_sandbox("code/analysis.R")
  
  # ... perform tests ...
  
  # Clean up without explicitly passing sandbox
  cleanup_sandbox()
})
```

## License

MIT © Dianyi Yang
