# These tests verify snapshot functionality
# Note: We test by sourcing scripts, not calling snapshot() directly in tests

test_that("find_root finds project root with .git", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  dir.create(file.path(temp_project, "subdir"), recursive = TRUE)
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  # Source a script that calls find_root (simulates interactive use)
  script <- file.path(temp_project, "test.R")
  writeLines('root <- find_root(); saveRDS(root, "root.rds")', script)
  
  withr::with_dir(temp_project, {
    source("test.R")
    root <- readRDS("root.rds")
    expect_equal(normalizePath(root), normalizePath(temp_project))
  })
})


test_that("snapshot creates .md file when run interactively", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  # Create a script that uses snapshot
  script <- file.path(temp_project, "analysis.R")
  writeLines(c(
    'test_value <- data.frame(x = 1:5, y = 6:10)',
    'snapshot(test_value, "test_snapshot")'
  ), script)
  
  withr::with_dir(temp_project, {
    # Source the script (simulates interactive use, not testing mode)
    source("analysis.R")
    
    snapshot_path <- file.path(temp_project, "_resultcheck_snapshots", "analysis", "test_snapshot.md")
    expect_true(file.exists(snapshot_path))
    expect_equal(tools::file_ext(snapshot_path), "md")
    
    # Check content is human-readable
    content <- readLines(snapshot_path)
    expect_true(any(grepl("# Snapshot:", content)))
    expect_true(any(grepl("data.frame", content)))
  })
})


test_that("snapshot matches when run with same data", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  script <- file.path(temp_project, "analysis.R")
  writeLines(c(
    'test_value <- data.frame(x = 1:5, y = 6:10)',
    'snapshot(test_value, "test_snapshot")'
  ), script)
  
  withr::with_dir(temp_project, {
    # First run
    source("analysis.R")
    
    # Second run - should match
    expect_message(
      source("analysis.R"),
      "Snapshot matches"
    )
  })
})


test_that("snapshot works with different object types", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  script <- file.path(temp_project, "analysis.R")
  writeLines(c(
    'list_obj <- list(a = 1:5, b = "test")',
    'snapshot(list_obj, "list_snap")',
    'model <- lm(mpg ~ wt, data = mtcars)',
    'snapshot(model, "model_snap")',
    'vec <- c(1, 2, 3)',
    'snapshot(vec, "vec_snap")'
  ), script)
  
  withr::with_dir(temp_project, {
    source("analysis.R")
    
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis", "list_snap.md")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis", "model_snap.md")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis", "vec_snap.md")))
  })
})


test_that("snapshot organizes by script name when specified", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  script1 <- file.path(temp_project, "script1.R")
  writeLines('snapshot(data.frame(a = 1), "snap1", script_name = "custom1")', script1)
  
  script2 <- file.path(temp_project, "script2.R")
  writeLines('snapshot(data.frame(b = 2), "snap2", script_name = "custom2")', script2)
  
  withr::with_dir(temp_project, {
    source("script1.R")
    source("script2.R")
    
    expect_true(dir.exists(file.path(temp_project, "_resultcheck_snapshots", "custom1")))
    expect_true(dir.exists(file.path(temp_project, "_resultcheck_snapshots", "custom2")))
  })
})
