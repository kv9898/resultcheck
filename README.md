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
