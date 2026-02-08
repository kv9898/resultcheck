test_that("setup_sandbox creates a temporary directory", {
  # Create a simple test file
  test_file <- tempfile(fileext = ".txt")
  writeLines("test content", test_file)
  on.exit(unlink(test_file))

  withr::with_dir(dirname(test_file), {
    # Setup sandbox
    sandbox <- setup_sandbox(basename(test_file))

    # Check that sandbox was created
    expect_s3_class(sandbox, "resultcheck_sandbox")
    expect_true(dir.exists(sandbox$path))
    expect_true(nchar(sandbox$id) > 0)

    # Clean up
    cleanup_sandbox(sandbox)
  })
})


test_that("setup_sandbox copies files with directory structure", {
  # Create test directory structure
  temp_root <- tempfile()
  dir.create(temp_root)
  dir.create(file.path(temp_root, "data"), recursive = TRUE)

  test_file1 <- file.path(temp_root, "data", "test1.txt")
  writeLines("content 1", test_file1)

  on.exit(unlink(temp_root, recursive = TRUE))

  # Setup sandbox with working directory set to temp_root
  withr::with_dir(temp_root, {
    sandbox <- setup_sandbox(c("data/test1.txt"))
    on.exit(cleanup_sandbox(sandbox), add = TRUE)

    # Check that file was copied with directory structure
    expect_true(file.exists(file.path(sandbox$path, "data", "test1.txt")))

    # Check content
    copied_content <- readLines(file.path(sandbox$path, "data", "test1.txt"))
    expect_equal(copied_content, "content 1")
  })
})


test_that("setup_sandbox handles custom temp base", {
  # Create custom temp base
  custom_base <- tempfile()
  dir.create(custom_base)
  on.exit(unlink(custom_base, recursive = TRUE))

  # Create a test file
  test_file <- tempfile(fileext = ".txt")
  writeLines("test", test_file)
  on.exit(unlink(test_file), add = TRUE)
  withr::with_dir(dirname(test_file), {
    # Setup sandbox with custom base
    sandbox <- setup_sandbox(basename(test_file), temp_base = custom_base)
    on.exit(cleanup_sandbox(sandbox), add = TRUE)

    # Check that sandbox is in custom base
    expect_true(grepl(custom_base, sandbox$path, fixed = TRUE))
  })
})


test_that("setup_sandbox warns about missing files", {
  expect_warning(
    sandbox <- setup_sandbox("nonexistent_file.txt"),
    "File not found"
  )

  # Clean up if sandbox was created
  if (exists("sandbox")) {
    cleanup_sandbox(sandbox)
  }
})


test_that("setup_sandbox stores last sandbox in package environment", {
  test_file <- tempfile(fileext = ".txt")
  writeLines("test", test_file)
  on.exit(unlink(test_file))
  withr::with_dir(dirname(test_file), {
    sandbox <- setup_sandbox(basename(test_file))
    on.exit(cleanup_sandbox(sandbox), add = TRUE)

    # Check that it's stored
    expect_identical(resultcheck:::.resultcheck_env$last_sandbox, sandbox)
  })
})


test_that("run_in_sandbox executes script in sandbox directory", {
  skip_if_not_installed("withr")

  # Create a test script
  script_file <- tempfile(fileext = ".R")
  writeLines(
    c(
      'writeLines("test output", "output.txt")',
      'saveRDS(getwd(), "wd.rds")'
    ),
    script_file
  )
  on.exit(unlink(script_file))

  # Create sandbox
  sandbox <- setup_sandbox(character(0))
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  # Run script in sandbox
  run_in_sandbox(script_file, sandbox)

  # Check that output was created in sandbox
  expect_true(file.exists(file.path(sandbox$path, "output.txt")))

  # Check that script ran in sandbox directory
  saved_wd <- readRDS(file.path(sandbox$path, "wd.rds"))
  expect_equal(normalizePath(saved_wd), normalizePath(sandbox$path))
})


test_that("run_in_sandbox uses last sandbox by default", {
  skip_if_not_installed("withr")

  # Create a test script
  script_file <- tempfile(fileext = ".R")
  writeLines('writeLines("test", "output.txt")', script_file)
  on.exit(unlink(script_file))

  # Create sandbox (which becomes the last sandbox)
  sandbox <- setup_sandbox(character(0))
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  # Run without specifying sandbox
  run_in_sandbox(script_file)

  # Check that output was created
  expect_true(file.exists(file.path(sandbox$path, "output.txt")))
})


test_that("run_in_sandbox suppresses messages and warnings", {
  skip_if_not_installed("withr")

  # Create a test script with messages and warnings
  script_file <- tempfile(fileext = ".R")
  writeLines(
    c(
      'message("This is a message")',
      'warning("This is a warning")'
    ),
    script_file
  )
  on.exit(unlink(script_file))

  # Create sandbox
  sandbox <- setup_sandbox(character(0))
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  # Run with suppression (default) - should not show messages/warnings
  expect_silent(run_in_sandbox(script_file, sandbox))
})


test_that("run_in_sandbox errors on missing script", {
  sandbox <- setup_sandbox(character(0))
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  expect_error(
    run_in_sandbox("nonexistent_script.R", sandbox),
    "Script file not found"
  )
})


test_that("run_in_sandbox errors without sandbox", {
  # Clear last sandbox
  resultcheck:::.reset_last_sandbox()

  script_file <- tempfile(fileext = ".R")
  writeLines('1 + 1', script_file)
  on.exit(unlink(script_file))

  expect_error(
    run_in_sandbox(script_file),
    "No sandbox specified"
  )
})


test_that("cleanup_sandbox removes directory", {
  test_file <- tempfile(fileext = ".txt")
  writeLines("test", test_file)
  on.exit(unlink(test_file))

  withr::with_dir(dirname(test_file), {
    sandbox <- setup_sandbox(basename(test_file))

    # Check directory exists
    expect_true(dir.exists(sandbox$path))

    # Clean up
    result <- cleanup_sandbox(sandbox)

    # Check directory is gone
    expect_false(dir.exists(sandbox$path))
    expect_true(result)
  })
})


test_that("cleanup_sandbox clears last_sandbox", {
  test_file <- tempfile(fileext = ".txt")
  writeLines("test", test_file)
  on.exit(unlink(test_file))

  withr::with_dir(dirname(test_file), {
    sandbox <- setup_sandbox(basename(test_file))

    # Verify it's stored
    expect_false(is.null(resultcheck:::.resultcheck_env$last_sandbox))

    # Clean up
    cleanup_sandbox(sandbox)

    # Check it's cleared
    expect_null(resultcheck:::.resultcheck_env$last_sandbox)
  })
})


test_that("cleanup_sandbox uses last sandbox by default", {
  test_file <- tempfile(fileext = ".txt")
  writeLines("test", test_file)
  on.exit(unlink(test_file))

  withr::with_dir(dirname(test_file), {
    sandbox <- setup_sandbox(basename(test_file))
    sandbox_path <- sandbox$path

    # Clean up without specifying sandbox
    cleanup_sandbox()

    # Check directory is gone
    expect_false(dir.exists(sandbox_path))
  })
})


test_that("cleanup_sandbox handles nonexistent directory gracefully", {
  test_file <- tempfile(fileext = ".txt")
  writeLines("test", test_file)
  on.exit(unlink(test_file))

  withr::with_dir(dirname(test_file), {
    sandbox <- setup_sandbox(basename(test_file))

    # Manually delete directory
    unlink(sandbox$path, recursive = TRUE)

    # Should warn but not error
    expect_warning(
      result <- cleanup_sandbox(sandbox),
      "does not exist"
    )
    expect_false(result)
  })
})


test_that("Full workflow: setup, run, cleanup", {
  skip_if_not_installed("withr")

  # Create test data file
  data_file <- tempfile(fileext = ".rds")
  saveRDS(data.frame(x = 1:5, y = 6:10), data_file)
  on.exit(unlink(data_file))

  withr::with_dir(dirname(data_file), {
    # Create test script
    script_file <- tempfile(fileext = ".R")
    writeLines(
      c(
        sprintf('data <- readRDS("%s")', basename(data_file)),
        'data$z <- data$x + data$y',
        'saveRDS(data, "output.rds")'
      ),
      script_file
    )
    on.exit(unlink(script_file), add = TRUE)

    # Full workflow
    sandbox <- setup_sandbox(basename(data_file))
    run_in_sandbox(script_file, sandbox)

    # Verify output
    output_file <- file.path(sandbox$path, "output.rds")
    expect_true(file.exists(output_file))

    result <- readRDS(output_file)
    expect_equal(result$z, c(7, 9, 11, 13, 15))

    # Cleanup
    cleanup_sandbox(sandbox)
    expect_false(dir.exists(sandbox$path))
  })
})


test_that("setup_sandbox rejects absolute paths", {
  # Test Unix-style absolute path
  expect_error(
    setup_sandbox("/etc/passwd"),
    "Absolute paths are not allowed"
  )
  
  # Test another Unix-style absolute path
  expect_error(
    setup_sandbox("/tmp/test.txt"),
    "Absolute paths are not allowed"
  )
  
  # On Windows, test drive letter paths (will only trigger on Windows)
  if (.Platform$OS.type == "windows") {
    expect_error(
      setup_sandbox("C:/test.txt"),
      "Absolute paths are not allowed"
    )
    
    expect_error(
      setup_sandbox("D:\\test.txt"),
      "Absolute paths are not allowed"
    )
  }
})


test_that("setup_sandbox rejects path traversal attempts", {
  # Test basic path traversal
  expect_error(
    setup_sandbox("../etc/passwd"),
    "Path traversal"
  )
  
  # Test nested path traversal
  expect_error(
    setup_sandbox("data/../../etc/passwd"),
    "Path traversal"
  )
  
  # Test path traversal in middle
  expect_error(
    setup_sandbox("a/../b/file.txt"),
    "Path traversal"
  )
  
  # Test Windows-style path traversal
  expect_error(
    setup_sandbox("data\\..\\file.txt"),
    "Path traversal"
  )
})


test_that("setup_sandbox accepts legitimate filenames with double dots", {
  # Create test file with .. in filename
  temp_root <- tempfile()
  dir.create(temp_root)
  test_file <- file.path(temp_root, "file..txt")
  writeLines("content", test_file)
  on.exit(unlink(temp_root, recursive = TRUE))
  
  withr::with_dir(temp_root, {
    # Should accept filename with .. that is not a path component
    sandbox <- setup_sandbox("file..txt")
    expect_s3_class(sandbox, "resultcheck_sandbox")
    expect_true(file.exists(file.path(sandbox$path, "file..txt")))
    cleanup_sandbox(sandbox)
  })
})


test_that("setup_sandbox accepts valid relative paths", {
  # Create test files
  test_file <- tempfile(fileext = ".txt")
  writeLines("test content", test_file)
  on.exit(unlink(test_file))
  
  withr::with_dir(dirname(test_file), {
    # Simple basename should work
    sandbox <- setup_sandbox(basename(test_file))
    expect_s3_class(sandbox, "resultcheck_sandbox")
    cleanup_sandbox(sandbox)
  })
  
  # Test with subdirectory
  temp_root <- tempfile()
  dir.create(temp_root)
  dir.create(file.path(temp_root, "subdir"), recursive = TRUE)
  test_file2 <- file.path(temp_root, "subdir", "test.txt")
  writeLines("content", test_file2)
  on.exit(unlink(temp_root, recursive = TRUE), add = TRUE)
  
  withr::with_dir(temp_root, {
    # Relative path with subdirectory should work
    sandbox <- setup_sandbox("subdir/test.txt")
    expect_s3_class(sandbox, "resultcheck_sandbox")
    expect_true(file.exists(file.path(sandbox$path, "subdir", "test.txt")))
    cleanup_sandbox(sandbox)
  })
})
