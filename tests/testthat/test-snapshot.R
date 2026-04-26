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


test_that("serialize_value respects selected methods", {
  val <- list(a = 1:3, b = "hello")

  out_default <- resultcheck:::serialize_value(val)
  out_print <- resultcheck:::serialize_value(val, methods = print)
  out_str   <- resultcheck:::serialize_value(val, methods = str)
  out_multi <- resultcheck:::serialize_value(
    val,
    methods = list(summary = summary, print = print, summary_again = summary)
  )

  # "print" output contains the "## print" header but not "## str"
  expect_true(any(grepl("^## print$", out_print)))
  expect_false(any(grepl("^## str$", out_print)))
  expect_false(any(grepl("## List Structure", out_print)))

  # "str" output contains the "## str" header but not "## print"
  expect_true(any(grepl("^## str$", out_str)))
  expect_false(any(grepl("^## print$", out_str)))

  # default output includes print and str sections
  expect_true(any(grepl("^## print$", out_default)))
  expect_true(any(grepl("^## str$", out_default)))
  expect_false(any(grepl("## List Structure", out_default)))

  # methods are applied in provided order
  headers <- out_multi[grepl("^## ", out_multi)]
  expect_equal(headers, c("## summary", "## print", "## summary_again"))
})


test_that("snapshot respects method parameter", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))

  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    val <- list(a = 1:3, id = "volatile_abc123")

    snapshot(val, "snap_print", script_name = "analysis", method = print)
    snapshot(val, "snap_str",   script_name = "analysis", method = str)
    snapshot(
      val,
      "snap_expr",
      script_name = "analysis",
      method = list(print = print, summary = summary)
    )
    snapshot(val, "snap_length", script_name = "analysis", method = length)

    content_print <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "snap_print.md"),
      warn = FALSE
    )
    content_str <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "snap_str.md"),
      warn = FALSE
    )
    content_expr <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "snap_expr.md"),
      warn = FALSE
    )
    content_length <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "snap_length.md"),
      warn = FALSE
    )

    # print-only snapshot has "## print" header
    expect_true(any(grepl("^## print$", content_print)))
    # str-only snapshot has "## str" header
    expect_true(any(grepl("^## str$", content_str)))

    # Neither should contain headers belonging to the other method
    expect_false(any(grepl("^## str$", content_print)))
    expect_false(any(grepl("^## print$", content_str)))

    expect_true(any(grepl("^## print$", content_expr)))
    expect_true(any(grepl("^## summary$", content_expr)))

    expect_true(any(grepl("^## length$", content_length)))
  })
})

test_that("coerce_snapshot_methods validates function-based methods", {
  expect_error(
    resultcheck:::coerce_snapshot_methods("print"),
    "must be a function or a non-empty list of functions"
  )
  expect_error(
    resultcheck:::coerce_snapshot_methods(list(print, "str")),
    "must be a function or a non-empty list of functions"
  )

  methods <- resultcheck:::coerce_snapshot_methods(list(print = print, str = str))
  expect_equal(unname(vapply(methods, `[[`, character(1), "label")), c("print", "str"))
  expect_identical(methods[[1]]$fn, print)
  expect_identical(methods[[2]]$fn, str)

  guessed <- resultcheck:::coerce_snapshot_methods(list(print, str))
  expect_equal(unname(vapply(guessed, `[[`, character(1), "label")), c("print", "str"))

  namespaced <- resultcheck:::coerce_snapshot_methods(
    stats::coef,
    method_expr = substitute(stats::coef)
  )
  expect_equal(unname(vapply(namespaced, `[[`, character(1), "label")), "stats::coef")

  fallback <- resultcheck:::coerce_snapshot_methods(list(function(x) x))
  expect_equal(unname(vapply(fallback, `[[`, character(1), "label")), "unnamed_method_1")
})

test_that("serialize_value reports method execution failures clearly", {
  assign("summary.fail_summary", function(object, ...) {
    stop("summary failed intentionally")
  }, envir = .GlobalEnv)
  on.exit(rm("summary.fail_summary", envir = .GlobalEnv), add = TRUE)

  x <- structure(list(a = 1), class = "fail_summary")
  expect_error(
    resultcheck:::serialize_value(x, methods = summary),
    "Snapshot method `summary` is not available for class `fail_summary`: summary failed intentionally"
  )
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
    # Match changed numeric output in both print() ("[1] ...") and str() ("num [...] ...")
    numeric_output_pattern <- "^\\[1\\]|^\\s*num \\["
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
    new_text <- resultcheck:::serialize_value(val2, methods = list(print = print, str = str))
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

test_that("snapshot defaults to print and str when method is omitted", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "default_methods_test", script_name = "analysis")

    content <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "default_methods_test.md"),
      warn = FALSE
    )
    expect_true(any(grepl("^## print$", content)))
    expect_true(any(grepl("^## str$", content)))
  })
})

test_that("snapshot rejects character method values", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    model <- lm(mpg ~ wt, data = mtcars)
    expect_error(
      snapshot(model, "char_method_test", script_name = "analysis", method = "print"),
      "must be a function or a non-empty list of functions"
    )
  })
})

test_that("snapshot uses class default methods from _resultcheck.yml", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  writeLines(
    c(
      "snapshot:",
      "  method_by_class:",
      "    lm: summary"
    ),
    file.path(temp_project, "_resultcheck.yml")
  )

  withr::with_dir(temp_project, {
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "class_default_test", script_name = "analysis")
    content <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "class_default_test.md"),
      warn = FALSE
    )
    expect_true(any(grepl("^## summary$", content)))
    expect_false(any(grepl("^## print$", content)))
  })
})

test_that("explicit method overrides class default methods", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  writeLines(
    c(
      "snapshot:",
      "  method_by_class:",
      "    lm: summary"
    ),
    file.path(temp_project, "_resultcheck.yml")
  )

  withr::with_dir(temp_project, {
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "class_override_test", script_name = "analysis", method = print)
    content <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "class_override_test.md"),
      warn = FALSE
    )
    expect_true(any(grepl("^## print$", content)))
    expect_false(any(grepl("^## summary$", content)))
  })
})

test_that("snapshot can read class defaults from separate R defaults file", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  defaults_path <- file.path(temp_project, "snapshot-method-overrides.R")
  writeLines(
    "method_by_class <- list(lm = 'summary')",
    defaults_path
  )
  writeLines(
    c(
      "snapshot:",
      "  method_defaults_file: snapshot-method-overrides.R"
    ),
    file.path(temp_project, "_resultcheck.yml")
  )

  withr::with_dir(temp_project, {
    cfg <- resultcheck:::read_resultcheck_config()
    expect_equal(cfg$snapshot$method_by_class$lm[[1]]$label, "summary")

    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "class_file_default_test", script_name = "analysis")
    content <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "class_file_default_test.md"),
      warn = FALSE
    )
    expect_true(any(grepl("^## summary$", content)))
    expect_false(any(grepl("^## print$", content)))
  })
})

test_that("inline class overrides take precedence over defaults file", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  defaults_path <- file.path(temp_project, "snapshot-method-overrides.R")
  writeLines(
    "method_by_class <- list(lm = 'print')",
    defaults_path
  )
  writeLines(
    c(
      "snapshot:",
      "  method_defaults_file: snapshot-method-overrides.R",
      "  method_by_class:",
      "    lm: summary"
    ),
    file.path(temp_project, "_resultcheck.yml")
  )

  withr::with_dir(temp_project, {
    cfg <- resultcheck:::read_resultcheck_config()
    expect_equal(cfg$snapshot$method_by_class$lm[[1]]$label, "summary")
  })
})

test_that("snapshot uses global method default when method is omitted", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  writeLines(
    c(
      "snapshot:",
      "  method: summary + print"
    ),
    file.path(temp_project, "_resultcheck.yml")
  )

  withr::with_dir(temp_project, {
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "global_default_test", script_name = "analysis")
    content <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "global_default_test.md"),
      warn = FALSE
    )
    headers <- content[grepl("^## ", content)]
    expect_equal(headers, c("## summary", "## print"))
    expect_true(any(grepl("^Coefficients:$", content)))
    expect_true(any(grepl("^Call:$", content)))
  })
})

test_that("snapshot labels namespaced methods from expression", {
  temp_project <- tempfile()
  dir.create(temp_project)
  dir.create(file.path(temp_project, ".git"))
  on.exit(unlink(temp_project, recursive = TRUE))

  withr::with_dir(temp_project, {
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "namespaced_method_test", script_name = "analysis", method = stats::coef)
    content <- readLines(
      file.path(temp_project, "tests/_resultcheck_snaps", "analysis", "namespaced_method_test.md"),
      warn = FALSE
    )
    expect_true(any(grepl("^## stats::coef$", content)))
  })
})
