# These tests verify snapshot functionality
# Note: We test by sourcing scripts, not calling snapshot() directly in tests

test_that("find_root finds project root with .git", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  dir.create(file.path(temp_project, "subdir"), recursive = TRUE)
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  # Test from root directory
  withr::with_dir(temp_project, {
    root <- find_root()
    expect_equal(normalizePath(root), normalizePath(temp_project))
  })
  
  # Test from subdirectory
  withr::with_dir(file.path(temp_project, "subdir"), {
    root <- find_root()
    expect_equal(normalizePath(root), normalizePath(temp_project))
  })
})


test_that("snapshot creates .md file when run interactively", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    test_value <- data.frame(x = 1:5, y = 6:10)
    snapshot(test_value, "test_snapshot", script_name = "analysis")
    
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
  
  withr::with_dir(temp_project, {
    test_value <- data.frame(x = 1:5, y = 6:10)
    
    # First run
    snapshot(test_value, "test_snapshot", script_name = "analysis")
    
    # Second run - should match
    expect_message(
      snapshot(test_value, "test_snapshot", script_name = "analysis"),
      "Snapshot matches"
    )
  })
})


test_that("snapshot works with different object types", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    list_obj <- list(a = 1:5, b = "test")
    snapshot(list_obj, "list_snap", script_name = "analysis")
    
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "model_snap", script_name = "analysis")
    
    vec <- c(1, 2, 3)
    snapshot(vec, "vec_snap", script_name = "analysis")
    
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
  
  withr::with_dir(temp_project, {
    snapshot(data.frame(a = 1), "snap1", script_name = "custom1")
    snapshot(data.frame(b = 2), "snap2", script_name = "custom2")
    
    expect_true(dir.exists(file.path(temp_project, "_resultcheck_snapshots", "custom1")))
    expect_true(dir.exists(file.path(temp_project, "_resultcheck_snapshots", "custom2")))
  })
})
