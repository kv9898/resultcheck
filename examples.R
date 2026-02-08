# Example Usage of resultcheck Sandboxing Functions
# This file demonstrates how to use the sandboxing functions

# Example 1: Basic usage
# ----------------------

library(resultcheck)

# Create some test data
test_data <- data.frame(x = 1:10, y = rnorm(10))
dir.create("data", showWarnings = FALSE)
saveRDS(test_data, "data/test_data.rds")

# Create a simple analysis script
script_content <- '
# Read data
data <- readRDS("data/test_data.rds")

# Perform analysis
data$z <- data$x * 2

# Save results
dir.create("output", showWarnings = FALSE)
saveRDS(data, "output/results.rds")
'

writeLines(script_content, "analysis.R")

# Now use sandboxing functions
sandbox <- setup_sandbox(c("data/test_data.rds"))
print(paste("Sandbox created at:", sandbox$path))

run_in_sandbox("analysis.R", sandbox)

# Check results
results_file <- file.path(sandbox$path, "output/results.rds")
if (file.exists(results_file)) {
  results <- readRDS(results_file)
  print("Results:")
  print(head(results))
}

# Cleanup
cleanup_sandbox(sandbox)

# Clean up test files
unlink("data", recursive = TRUE)
unlink("analysis.R")


# Example 2: Using with testthat
# --------------------------------

library(testthat)
library(resultcheck)

test_that("Analysis produces expected output", {
  # Create test data
  dir.create("data", showWarnings = FALSE)
  test_data <- data.frame(a = 1:5, b = 6:10)
  saveRDS(test_data, "data/input.rds")
  
  # Create analysis script
  script <- '
  data <- readRDS("data/input.rds")
  data$sum <- data$a + data$b
  dir.create("results", showWarnings = FALSE)
  saveRDS(data, "results/output.rds")
  '
  writeLines(script, "compute.R")
  
  # Setup sandbox
  sandbox <- setup_sandbox(c("data/input.rds"))
  
  # Run analysis
  run_in_sandbox("compute.R", sandbox)
  
  # Verify output
  output_path <- file.path(sandbox$path, "results/output.rds")
  expect_true(file.exists(output_path))
  
  result <- readRDS(output_path)
  expect_equal(result$sum, c(7, 9, 11, 13, 15))
  
  # Cleanup
  cleanup_sandbox(sandbox)
  unlink("data", recursive = TRUE)
  unlink("compute.R")
})


# Example 3: Using default sandbox
# ---------------------------------

library(resultcheck)

# Create sandbox (becomes the default)
setup_sandbox(character(0))  # Empty sandbox

# Run script (uses default sandbox)
script <- 'writeLines("Hello from sandbox!", "greeting.txt")'
writeLines(script, "hello.R")
run_in_sandbox("hello.R")  # No need to specify sandbox

# Cleanup (uses default sandbox)
cleanup_sandbox()  # No need to specify sandbox
unlink("hello.R")


# Example 4: Matching the original use case from the issue
# ---------------------------------------------------------

library(testthat)
library(resultcheck)

test_that("fiscal script setup and execution", {
  # Setup: Create sandbox with required files
  sandbox <- setup_sandbox(c(
    "data/panel_data_pca.rds",
    "data/fiscal.dta",
    "save/regModels.RData",
    "helper/f_test_fiscal.R"
  ))
  
  # Run fiscal.R in sandbox
  run_in_sandbox("code/fiscal.R", sandbox)
  
  # Basic check that script completed
  expect_true(file.exists(file.path(sandbox$path, "data/panel_data_fiscal.rds")))
  expect_true(file.exists(file.path(sandbox$path, "save/regModels_fiscal.RData")))
  expect_true(file.exists(file.path(sandbox$path, "save/regTable_fiscal.RData")))
  
  # Cleanup
  cleanup_sandbox(sandbox)
})
