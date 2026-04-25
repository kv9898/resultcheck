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
    
    snapshot_path <- file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "test_snapshot.md")
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
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "model_snap.md"),
      warn = FALSE
    )
    
    expect_true(file.exists(file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "list_snap.md")))
    expect_true(file.exists(file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "model_snap.md")))
    expect_true(file.exists(file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "vec_snap.md")))
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
    
    expect_true(dir.exists(file.path(temp_project, "tests/_resultcheck_snaps", "custom1")))
    expect_true(dir.exists(file.path(temp_project, "tests/_resultcheck_snaps", "custom2")))
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

  # "both" includes print output and structure output
  expect_true(any(grepl("## Object", out_both)))
  expect_true(any(grepl("^## Structure$", out_both)))
  expect_false(any(grepl("## List Structure", out_both)))
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
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "snap_print.md"),
      warn = FALSE
    )
    content_str <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "snap_str.md"),
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


# ── [ignored] marker tests ────────────────────────────────────────────────────

test_that("mask_ignored_lines replaces new lines at [ignored] positions", {
  old_text <- c("line 1", "[ignored]", "line 3")
  new_text <- c("line 1", "different value", "line 3")

  result <- resultcheck:::mask_ignored_lines(old_text, new_text)
  expect_equal(result, c("line 1", "[ignored]", "line 3"))
})


test_that("mask_ignored_lines handles [ignored] with surrounding whitespace", {
  old_text <- c("  [ignored]  ", "normal line")
  new_text <- c("some value",    "normal line")

  result <- resultcheck:::mask_ignored_lines(old_text, new_text)
  expect_equal(result, c("[ignored]", "normal line"))
})


test_that("compare_snapshot_text returns NULL when only [ignored] lines differ", {
  old_text <- c(
    "# Snapshot: numeric",
    "",
    "## Value",
    "[ignored]",
    "[ignored]"
  )
  new_text <- c(
    "# Snapshot: numeric",
    "",
    "## Value",
    "  ..- attr(*, \"scaled:center\")= num 2.41e-17",
    "  ..- attr(*, \"scaled:center\")= num 2.98e-17"
  )

  result <- resultcheck:::compare_snapshot_text(old_text, new_text)
  expect_null(result)
})


test_that("snapshot in testing mode passes when differing lines are [ignored]", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    val1 <- c(1.0, 2.0, 3.0)
    snapshot(val1, "snap_ignored_mode", script_name = "analysis")

    snap_file <- file.path(temp_project, "tests/_resultcheck_snaps",
                           "analysis", "snap_ignored_mode.md")

    lines <- readLines(snap_file)
    # Match changed numeric output in both print() ("[1] ...") and str() ("num [1:3] ...")
    numeric_output_pattern <- "^\\[1\\]|^\\s*num \\[1:3\\]"
    value_lines <- which(grepl(numeric_output_pattern, lines))
    lines[value_lines] <- "[ignored]"
    writeLines(lines, snap_file)

    # Simulate testing mode by writing a script and running it in a sandbox
    script_content <- paste0(
      'val2 <- c(99.0, 2.0, 3.0)\n',
      'resultcheck::snapshot(val2, "snap_ignored_mode", script_name = "analysis")\n'
    )
    writeLines(script_content, file.path(temp_project, "test_script.R"))

    sandbox <- setup_sandbox(character(0))
    expect_no_error(run_in_sandbox("test_script.R", sandbox))
    cleanup_sandbox(sandbox)
  })
})


test_that("mask_ignored_lines preserves [ignored] marker in masked new_text", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    val <- c(1.0, 2.0, 3.0)
    snapshot(val, "ignored_preserve_test", script_name = "analysis")

    snap_file <- file.path(temp_project, "tests/_resultcheck_snaps",
                           "analysis", "ignored_preserve_test.md")

    lines <- readLines(snap_file)
    value_line <- which(grepl("^\\[1\\]", lines))[1]
    lines[value_line] <- "[ignored]"
    writeLines(lines, snap_file)

    old_text <- readLines(snap_file)
    val2 <- c(99.0, 2.0, 3.0)
    new_text <- resultcheck:::serialize_value(val2, method = "both")
    new_text <- resultcheck:::normalize_snapshot_text(new_text)

    masked <- resultcheck:::mask_ignored_lines(old_text, new_text)
    expect_equal(masked[value_line], "[ignored]")
  })
})


# ── precision rounding tests ──────────────────────────────────────────────────

test_that("round_snapshot_numbers rounds decimal numbers", {
  text <- c("num 2.41e-17", "num 1.22", "int 5")

  result <- resultcheck:::round_snapshot_numbers(text, digits = 10L)

  expect_equal(result[1], "num 0")
  expect_equal(result[2], "num 1.22")
  expect_equal(result[3], "int 5")
})


test_that("round_snapshot_numbers leaves non-numeric text unchanged", {
  text <- c("# Snapshot: data.frame", "## Structure", "chr \"hello\"")
  result <- resultcheck:::round_snapshot_numbers(text, digits = 5L)
  expect_equal(result, text)
})


test_that("compare_snapshot_text returns NULL with precision when tiny diffs exist", {
  old_text <- c(
    "# Snapshot: numeric",
    "",
    "## Value",
    "  ..- attr(*, \"scaled:center\")= num 2.41e-17"
  )
  new_text <- c(
    "# Snapshot: numeric",
    "",
    "## Value",
    "  ..- attr(*, \"scaled:center\")= num 1.63e-17"
  )

  expect_false(is.null(
    resultcheck:::compare_snapshot_text(old_text, new_text)
  ))
  expect_null(
    resultcheck:::compare_snapshot_text(old_text, new_text, precision = 10L)
  )
})


test_that("snapshot reads precision from _resultcheck.yml and stores rounded values", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  writeLines(c("snapshot:", "  precision: 5"),
             file.path(temp_project, "_resultcheck.yml"))

  withr::with_dir(temp_project, {
    val <- 1.123456789
    snapshot(val, "precision_test", script_name = "analysis")

    snap_file <- file.path(temp_project, "tests/_resultcheck_snaps",
                           "analysis", "precision_test.md")
    content <- readLines(snap_file)
    expect_true(any(grepl("1.12346", content, fixed = TRUE)))
    expect_false(any(grepl("1.123456789", content, fixed = TRUE)))
  })
})

test_that("snapshot uses configured snapshot.dir from _resultcheck.yml", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  writeLines(
    c("snapshot:", "  dir: custom_snapshots"),
    file.path(temp_project, "_resultcheck.yml")
  )

  withr::with_dir(temp_project, {
    snapshot(letters[1:3], "custom_dir_test", script_name = "analysis")

    snap_file <- file.path(
      temp_project, "custom_snapshots", "analysis", "custom_dir_test.md"
    )
    expect_true(file.exists(snap_file))
  })
})

test_that("read_resultcheck_config supports legacy resultcheck.yml", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  writeLines(
    c("snapshot:", "  precision: 4"),
    file.path(temp_project, "resultcheck.yml")
  )

  withr::with_dir(temp_project, {
    cfg <- resultcheck:::read_resultcheck_config()
    expect_equal(cfg$snapshot$precision, 4)
  })
})


test_that("read_resultcheck_config returns empty list when no yml exists", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    cfg <- resultcheck:::read_resultcheck_config()
    expect_type(cfg, "list")
    expect_length(cfg, 0L)
  })
})
