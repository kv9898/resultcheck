test_that("find_root finds project root with .git", {
  # Create a temporary project structure
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


test_that("find_root finds project root with .Rproj", {
  # Create a temporary project structure
  temp_project <- tempfile()
  dir.create(temp_project)
  file.create(file.path(temp_project, "myproject.Rproj"))
  dir.create(file.path(temp_project, "subdir"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    root <- find_root()
    expect_equal(normalizePath(root), normalizePath(temp_project))
  })
})


test_that("find_root finds project root with resultcheck.yml", {
  # Create a temporary project structure
  temp_project <- tempfile()
  dir.create(temp_project)
  file.create(file.path(temp_project, "resultcheck.yml"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    root <- find_root()
    expect_equal(normalizePath(root), normalizePath(temp_project))
  })
})


test_that("find_root errors when no project root found", {
  # Create a temporary directory without any markers
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  withr::with_dir(temp_dir, {
    expect_error(
      find_root(),
      "Could not find project root"
    )
  })
})


test_that("snapshot creates new snapshot file", {
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Create a test value
    test_value <- data.frame(x = 1:5, y = 6:10)
    
    # Capture messages
    expect_message(
      result <- snapshot(test_value, "test_snapshot", script_name = "test_script", interactive = FALSE),
      "New snapshot saved"
    )
    
    # Check that snapshot file was created
    snapshot_path <- file.path(temp_project, "_resultcheck_snapshots", "test_script", "test_snapshot.rds")
    expect_true(file.exists(snapshot_path))
    
    # Check that saved value matches
    saved_value <- readRDS(snapshot_path)
    expect_equal(saved_value, test_value)
  })
})


test_that("snapshot detects no changes when values match", {
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Create and save initial snapshot
    test_value <- data.frame(x = 1:5, y = 6:10)
    snapshot(test_value, "test_snapshot", script_name = "test_script", interactive = FALSE)
    
    # Try snapshotting the same value again
    expect_message(
      snapshot(test_value, "test_snapshot", script_name = "test_script", interactive = FALSE),
      "Snapshot matches"
    )
  })
})


test_that("snapshot detects differences when values change", {
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Create and save initial snapshot
    test_value1 <- data.frame(x = 1:5, y = 6:10)
    snapshot(test_value1, "test_snapshot", script_name = "test_script", interactive = FALSE)
    
    # Create a different value
    test_value2 <- data.frame(x = 1:5, y = 11:15)
    
    # Snapshot should detect differences
    expect_message(
      result <- snapshot(test_value2, "test_snapshot", script_name = "test_script", interactive = FALSE),
      "Snapshot differences found"
    )
    
    expect_false(result)
  })
})


test_that("snapshot organizes files by script name", {
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Create snapshots for different scripts
    snapshot(data.frame(a = 1), "snap1", script_name = "script1", interactive = FALSE)
    snapshot(data.frame(b = 2), "snap2", script_name = "script2", interactive = FALSE)
    
    # Check directory structure
    expect_true(dir.exists(file.path(temp_project, "_resultcheck_snapshots", "script1")))
    expect_true(dir.exists(file.path(temp_project, "_resultcheck_snapshots", "script2")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "script1", "snap1.rds")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "script2", "snap2.rds")))
  })
})


test_that("expect_snapshot_value works with existing snapshot", {
  skip_if_not_installed("testthat")
  
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Create initial snapshot
    test_value <- data.frame(x = 1:5, y = 6:10)
    snapshot(test_value, "test_snap", script_name = "test", interactive = FALSE)
    
    # expect_snapshot_value should pass with same value
    expect_silent(expect_snapshot_value(test_value, "test_snap", script_name = "test"))
  })
})


test_that("expect_snapshot_value fails with different value", {
  skip_if_not_installed("testthat")
  
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Create initial snapshot
    test_value1 <- data.frame(x = 1:5, y = 6:10)
    snapshot(test_value1, "test_snap", script_name = "test", interactive = FALSE)
    
    # expect_snapshot_value should fail with different value
    test_value2 <- data.frame(x = 1:5, y = 11:15)
    expect_error(
      expect_snapshot_value(test_value2, "test_snap", script_name = "test")
    )
  })
})


test_that("expect_snapshot_value fails when snapshot doesn't exist", {
  skip_if_not_installed("testthat")
  
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Try to use expect_snapshot_value without creating snapshot first
    test_value <- data.frame(x = 1:5)
    expect_error(
      expect_snapshot_value(test_value, "nonexistent", script_name = "test"),
      "Snapshot does not exist"
    )
  })
})


test_that("snapshot works with different object types", {
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Test with different types
    
    # List
    list_obj <- list(a = 1:5, b = "test", c = TRUE)
    snapshot(list_obj, "list_snap", script_name = "types", interactive = FALSE)
    
    # Model
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "model_snap", script_name = "types", interactive = FALSE)
    
    # Vector
    vec <- c(1, 2, 3, 4, 5)
    snapshot(vec, "vec_snap", script_name = "types", interactive = FALSE)
    
    # Check all were created
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "types", "list_snap.rds")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "types", "model_snap.rds")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "types", "vec_snap.rds")))
  })
})


test_that("get_snapshot_path creates snapshot directory", {
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Get snapshot path (should create directory)
    path <- resultcheck:::get_snapshot_path("test", script_name = "my_script")
    
    # Check directory was created
    snapshot_dir <- file.path(temp_project, "_resultcheck_snapshots", "my_script")
    expect_true(dir.exists(snapshot_dir))
    
    # Check path format
    expect_match(path, "my_script")
    expect_match(path, "test.rds")
  })
})


test_that("snapshot handles script names with .R extension", {
  # Create a temporary project
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  
  on.exit(unlink(temp_project, recursive = TRUE))
  
  withr::with_dir(temp_project, {
    # Create snapshot with .R extension in script name
    test_value <- data.frame(x = 1:3)
    snapshot(test_value, "snap1", script_name = "analysis.R", interactive = FALSE)
    
    # Should store under "analysis", not "analysis.R"
    expect_true(dir.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis", "snap1.rds")))
  })
})
