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

    model_snapshot <- readLines(
      file.path(temp_project, "_resultcheck_snapshots", "analysis", "model_snap.md"),
      warn = FALSE
    )
    
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis", "list_snap.md")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis", "model_snap.md")))
    expect_true(file.exists(file.path(temp_project, "_resultcheck_snapshots", "analysis", "vec_snap.md")))
    expect_true(any(grepl('<environment: <normalized>>', model_snapshot, fixed = TRUE)))
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


test_that("compare_snapshot_text ignores .Environment differences", {
  old_text <- c(
    "# Snapshot: lm",
    "",
    "## List Structure",
    "  .. ..- attr(*, \".Environment\")=<environment: 0x000001eb76e707a8> "
  )

  new_text <- c(
    "# Snapshot: lm",
    "",
    "## List Structure",
    "  .. ..- attr(*, \".Environment\")=<environment: R_GlobalEnv> "
  )

  differences <- resultcheck:::compare_snapshot_text(old_text, new_text)

  expect_null(differences)
})


test_that("serialize_value respects method = 'print'", {
  val <- list(a = 1:3, b = "hello")

  out_both  <- resultcheck:::serialize_value(val, method = "both")
  out_print <- resultcheck:::serialize_value(val, method = "print")
  out_str   <- resultcheck:::serialize_value(val, method = "str")

  # "print" output contains the "## Object" header but not "## Structure"
  expect_true(any(grepl("## Object", out_print)))
  expect_false(any(grepl("## Structure", out_print)))
  expect_false(any(grepl("## List Structure", out_print)))

  # "str" output contains the "## Structure" header but not "## Object"
  expect_true(any(grepl("## Structure", out_str)))
  expect_false(any(grepl("## Object", out_str)))

  # "both" (default for list) uses List Structure only (type-specific logic)
  expect_true(any(grepl("## List Structure", out_both)))
  expect_false(any(grepl("## Object", out_both)))
  expect_false(any(grepl("^## Structure$", out_both)))
})


test_that("snapshot respects method parameter", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    val <- list(a = 1:3, id = "volatile_abc123")

    snapshot(val, "snap_print", script_name = "analysis", method = "print")
    snapshot(val, "snap_str",   script_name = "analysis", method = "str")

    content_print <- readLines(
      file.path(temp_project, "_resultcheck_snapshots", "analysis", "snap_print.md"),
      warn = FALSE
    )
    content_str <- readLines(
      file.path(temp_project, "_resultcheck_snapshots", "analysis", "snap_str.md"),
      warn = FALSE
    )

    # print-only snapshot has "## Object" header
    expect_true(any(grepl("## Object", content_print)))
    # str-only snapshot has "## Structure" header
    expect_true(any(grepl("## Structure", content_str)))

    # Neither should contain headers belonging to the other method
    expect_false(any(grepl("## Structure", content_print)))
    expect_false(any(grepl("## Object", content_str)))
  })
})

