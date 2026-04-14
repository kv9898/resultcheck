#' Get project root for sandbox operations
#' 
#' Internal helper to get project root, falling back to current directory
#' if root cannot be determined.
#' 
#' @return Character path to project root or current working directory
#' @keywords internal
.get_project_root <- function() {
  tryCatch({
    find_root()
  }, error = function(e) {
    getwd()
  })
}


#' Run Code Inside a Temporary Example Project
#'
#' Creates a self-contained example project under \code{tempdir()}, including:
#' \itemize{
#'   \item \code{_resultcheck.yml} (project root marker)
#'   \item \code{analysis.R} with \code{snapshot(model, "model")}
#'   \item matching and mismatched snapshot files
#'   \item \code{tests/testthat/test-analysis.R}
#' }
#' then temporarily sets the working directory to that project while
#' evaluating \code{code}.
#'
#' @param code Code to evaluate inside the temporary example project.
#' @param mismatch Logical. If TRUE, replaces the active snapshot with a
#'   mismatched version before evaluating \code{code}.
#'
#' @return The value of \code{code}.
#'
#' @export
#'
#' @examples
#' with_example({
#'   root <- find_root()
#'   print(root)
#' })
with_example <- function(code, mismatch = FALSE) {
  example_root <- tempfile("resultcheck-example-", tmpdir = tempdir())
  dir.create(example_root, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(example_root, recursive = TRUE, force = TRUE), add = TRUE)

  dir.create(file.path(example_root, "tests", "_resultcheck_snaps", "analysis"),
             recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(example_root, "tests", "testthat"),
             recursive = TRUE, showWarnings = FALSE)

  writeLines("# Example project root marker",
             file.path(example_root, "_resultcheck.yml"))

  writeLines(
    c(
      'model <- lm(mpg ~ wt, data = mtcars)',
      'resultcheck::snapshot(model, "model")'
    ),
    file.path(example_root, "analysis.R")
  )

  model <- lm(mpg ~ wt, data = mtcars)
  matching_snapshot_text <- serialize_value(model, method = "both")
  snapshot_path <- file.path(
    example_root, "tests", "_resultcheck_snaps", "analysis", "model.md"
  )
  mismatch_path <- file.path(
    example_root, "tests", "_resultcheck_snaps", "analysis", "model_mismatch.md"
  )
  writeLines(matching_snapshot_text, snapshot_path)

  mismatch_text <- matching_snapshot_text
  numeric_pattern <- "[-+]?[0-9]*\\.?[0-9]+([eE][-+]?[0-9]+)?"
  first_numeric <- which(grepl(numeric_pattern, mismatch_text, perl = TRUE))[1]
  if (!is.na(first_numeric)) {
    line <- mismatch_text[first_numeric]
    m <- regexpr(numeric_pattern, line, perl = TRUE)
    if (m[1] != -1L) {
      matched <- regmatches(line, m)
      digits <- if (grepl("\\.", matched)) nchar(sub(".*\\.", "", matched)) else 0L
      altered_number <- format(
        round(as.numeric(matched) + 1, digits),
        nsmall = digits,
        scientific = FALSE
      )
      regmatches(line, m) <- altered_number
      mismatch_text[first_numeric] <- line
    }
  }
  writeLines(mismatch_text, mismatch_path)

  writeLines(
    c(
      "library(testthat)",
      "library(resultcheck)",
      "",
      'test_that("run_tested_script", {',
      '  sandbox <- setup_sandbox("analysis.R")',
      "  on.exit(cleanup_sandbox(sandbox), add = TRUE)",
      "",
      '  expect_true(run_in_sandbox("analysis.R", sandbox))',
      "})"
    ),
    file.path(example_root, "tests", "testthat", "test-analysis.R")
  )

  if (isTRUE(mismatch)) {
    file.copy(mismatch_path, snapshot_path, overwrite = TRUE)
  }

  if (!requireNamespace("withr", quietly = TRUE)) {
    stop("Package 'withr' is required but not installed. ",
         "Please install it with: install.packages('withr')")
  }

  expr <- substitute(code)
  withr::with_dir(example_root, eval.parent(expr))
}


#' Setup a Sandbox Environment for Testing
#'
#' Creates a temporary directory and copies specified files and/or directories
#' into it while preserving their path structure. This is useful for testing
#' empirical analysis scripts in isolation.
#'
#' @param files Character vector of relative file or directory paths to copy
#'   to the sandbox.  Paths are resolved relative to the project root (found
#'   using \code{find_root()}); if the project root cannot be determined the
#'   current working directory is used.  When a path refers to a directory,
#'   the entire directory is copied recursively.  Absolute paths and path
#'   traversal attempts (e.g., \code{..}) are rejected for security.
#'   Snapshot files do \emph{not} need to be listed here: \code{snapshot()}
#'   always reads snapshots from the project root, not from the sandbox.
#' @param temp_base Optional. Custom location for the temporary directory.
#'   If NULL (default), uses \code{tempfile()}.
#'
#' @return A list with class "resultcheck_sandbox" containing:
#'   \item{path}{The path to the created temporary directory}
#'   \item{id}{A unique timestamp-based identifier for this sandbox}
#'
#' @export
#'
#' @examples
#' with_example({
#'   sandbox <- setup_sandbox("analysis.R")
#'   print(sandbox$path)
#'   cleanup_sandbox(sandbox)
#' })
setup_sandbox <- function(files, temp_base = NULL) {
  # Generate unique ID for this sandbox
  sandbox_id <- paste0(
    "sandbox_",
    format(Sys.time(), "%Y%m%d_%H%M%S"),
    "_",
    paste(sample(c(letters, 0:9), 8, replace = TRUE), collapse = "")
  )
  
  # Create temp directory
  if (is.null(temp_base)) {
    temp_dir <- tempfile(pattern = sandbox_id)
  } else {
    temp_dir <- file.path(temp_base, sandbox_id)
  }
  
  # Try to create the directory
  tryCatch({
    dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(temp_dir)) {
      stop("Failed to create sandbox directory: ", temp_dir)
    }
  }, error = function(e) {
    stop("Failed to create sandbox directory: ", e$message)
  })
  
  # Find project root to resolve file paths relative to it
  project_root <- .get_project_root()
  
  # Copy files/directories while preserving path structure
  for (file in files) {
    # Validate that path is relative (no absolute paths allowed)
    if (.Platform$OS.type == "windows") {
      # On Windows, check for drive letters or UNC paths
      is_absolute <- grepl("^[A-Za-z]:|^\\\\\\\\|^/", file)
    } else {
      # On Unix-like systems, check for leading slash
      is_absolute <- grepl("^/", file)
    }
    
    if (is_absolute) {
      stop("Absolute paths are not allowed. Please use relative paths only: ", file)
    }
    
    # Validate that path doesn't contain path traversal attempts
    # Split path and check each component for exactly ".."
    path_components <- strsplit(file, "[/\\\\]")[[1]]
    if (any(path_components == "..")) {
      stop("Path traversal (e.g., '..') is not allowed for security reasons: ", file)
    }
    
    # Resolve path relative to project root
    full_file_path <- file.path(project_root, file)
    
    if (dir.exists(full_file_path)) {
      # Copy directory recursively, preserving the relative path structure
      all_sub_files <- list.files(full_file_path, recursive = TRUE,
                                  all.files = TRUE, full.names = FALSE)
      for (subfile in all_sub_files) {
        src <- file.path(full_file_path, subfile)
        if (dir.exists(src)) next  # skip directory entries
        dst <- file.path(temp_dir, file, subfile)
        if (!dir.exists(dirname(dst))) {
          dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
        }
        tryCatch({
          file.copy(src, dst, overwrite = TRUE)
        }, error = function(e) {
          warning("Failed to copy file ", file.path(file, subfile), ": ", e$message)
        })
      }
    } else if (file.exists(full_file_path)) {
      # Determine the target path
      target_path <- file.path(temp_dir, file)
      
      # Create parent directories if needed
      target_dir <- dirname(target_path)
      if (!dir.exists(target_dir)) {
        dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
      }
      
      # Copy the file
      # Note: file.copy() follows symlinks and copies the target file's content,
      # not the symlink itself. This means even if 'file' is a symlink pointing
      # outside the current directory, the copied content will be in the sandbox.
      # This is the desired behavior for creating isolated test environments.
      tryCatch({
        file.copy(full_file_path, target_path, overwrite = TRUE)
      }, error = function(e) {
        warning("Failed to copy file ", file, ": ", e$message)
      })
    } else {
      warning("File not found, skipping: ", file)
    }
  }
  
  # Create and return sandbox object
  sandbox <- list(
    path = temp_dir,
    id = sandbox_id
  )
  class(sandbox) <- c("resultcheck_sandbox", "list")
  
  # Store in package environment for later retrieval
  .resultcheck_env$last_sandbox <- sandbox
  
  return(sandbox)
}


#' Run Code in a Sandbox Environment
#'
#' Executes an R script within a sandbox directory, suppressing messages,
#' warnings, and graphical output. This is useful for testing empirical
#' analysis scripts without polluting the console or creating unwanted plots.
#'
#' @param script_path Path to the R script to execute.
#' @param sandbox Optional. A sandbox object created by \code{setup_sandbox()}.
#'   If NULL (default), uses the most recently created sandbox.
#' @param suppress_messages Logical. Whether to suppress messages (default: TRUE).
#' @param suppress_warnings Logical. Whether to suppress warnings (default: TRUE).
#' @param capture_output Logical. Whether to capture output (default: TRUE).
#'
#' @return Invisible TRUE on successful execution.
#'
#' @export
#'
#' @examples
#' with_example({
#'   sandbox <- setup_sandbox("analysis.R")
#'   on.exit(cleanup_sandbox(sandbox), add = TRUE)
#'   run_in_sandbox("analysis.R", sandbox)
#' })
run_in_sandbox <- function(script_path, 
                           sandbox = NULL, 
                           suppress_messages = TRUE,
                           suppress_warnings = TRUE,
                           capture_output = TRUE) {
  # Get sandbox
  if (is.null(sandbox)) {
    if (is.null(.resultcheck_env$last_sandbox)) {
      stop("No sandbox specified and no previous sandbox found. ",
           "Please create a sandbox with setup_sandbox() first.")
    }
    sandbox <- .resultcheck_env$last_sandbox
  }
  
  # Validate sandbox
  if (!inherits(sandbox, "resultcheck_sandbox")) {
    stop("Invalid sandbox object. Please provide a sandbox created by setup_sandbox().")
  }
  
  if (!dir.exists(sandbox$path)) {
    stop("Sandbox directory does not exist: ", sandbox$path)
  }
  
  # Check if withr is available
  if (!requireNamespace("withr", quietly = TRUE)) {
    stop("Package 'withr' is required but not installed. ",
         "Please install it with: install.packages('withr')")
  }
  
  # Check if script exists in sandbox (preferred) or in project root
  script_in_sandbox <- file.path(sandbox$path, script_path)
  if (file.exists(script_in_sandbox)) {
    # Script was copied to sandbox, use it from there
    script_to_run <- script_path
  } else {
    # Try to find script in project root
    project_root <- .get_project_root()
    script_in_root <- file.path(project_root, script_path)
    
    if (file.exists(script_in_root)) {
      # Copy script to sandbox before running, preserving directory structure
      target_path <- file.path(sandbox$path, script_path)
      target_dir <- dirname(target_path)
      if (!dir.exists(target_dir)) {
        dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
      }
      file.copy(script_in_root, target_path, overwrite = TRUE)
      script_to_run <- script_path
    } else if (file.exists(script_path)) {
      # Fallback: script exists at an absolute path or relative to current directory
      # Check if it's an absolute path
      is_absolute <- if (.Platform$OS.type == "windows") {
        grepl("^[A-Za-z]:|^\\\\\\\\|^/", script_path)
      } else {
        grepl("^/", script_path)
      }
      
      if (is_absolute) {
        # For absolute paths, copy to sandbox root with basename only
        target_path <- file.path(sandbox$path, basename(script_path))
        file.copy(script_path, target_path, overwrite = TRUE)
        script_to_run <- basename(script_path)
      } else {
        # For relative paths, preserve directory structure
        target_path <- file.path(sandbox$path, script_path)
        target_dir <- dirname(target_path)
        if (!dir.exists(target_dir)) {
          dir.create(target_dir, recursive = TRUE, showWarnings = FALSE)
        }
        file.copy(script_path, target_path, overwrite = TRUE)
        script_to_run <- script_path
      }
    } else {
      stop("Script file not found: ", script_path)
    }
  }
  
  # Build the execution expression
  exec_expr <- quote(source(script_to_run, keep.source = TRUE))
  
  if (capture_output) {
    exec_expr <- bquote(capture.output(.(exec_expr)))
  }
  
  if (suppress_warnings) {
    exec_expr <- bquote(suppressWarnings(.(exec_expr)))
  }
  
  if (suppress_messages) {
    exec_expr <- bquote(suppressMessages(.(exec_expr)))
  }
  
  # Store original working directory for snapshot functions
  original_wd <- getwd()
  
  # Execute in sandbox directory with graphics suppressed
  tryCatch({
    withr::with_dir(sandbox$path, {
      # Store original WD in package environment so snapshot() can find project root
      .resultcheck_env$.resultcheck_original_wd <- original_wd
      on.exit({
        .resultcheck_env$.resultcheck_original_wd <- NULL
      }, add = TRUE)
      
      pdf(NULL)
      eval(exec_expr)
      dev.off()
    })
  }, error = function(e) {
    # Ensure cleanup happens even on error
    .resultcheck_env$.resultcheck_original_wd <- NULL
    stop("Error executing script in sandbox: ", e$message)
  })
  
  # Ensure cleanup (redundant but safe)
  .resultcheck_env$.resultcheck_original_wd <- NULL
  
  invisible(TRUE)
}


#' Clean Up a Sandbox Environment
#'
#' Removes a sandbox directory and all its contents. This should be called
#' after testing is complete to free up disk space.
#'
#' @param sandbox Optional. A sandbox object created by \code{setup_sandbox()}.
#'   If NULL (default), cleans up the most recently created sandbox.
#' @param force Logical. If TRUE (default), removes directory even if it
#'   contains files.
#'
#' @return Logical indicating success (invisible).
#'
#' @export
#'
#' @examples
#' with_example({
#'   sandbox <- setup_sandbox("analysis.R")
#'   cleanup_sandbox(sandbox)
#' })
cleanup_sandbox <- function(sandbox = NULL, force = TRUE) {
  # Get sandbox
  if (is.null(sandbox)) {
    if (is.null(.resultcheck_env$last_sandbox)) {
      warning("No sandbox specified and no previous sandbox found. Nothing to clean up.")
      return(invisible(FALSE))
    }
    sandbox <- .resultcheck_env$last_sandbox
  }
  
  # Validate sandbox
  if (!inherits(sandbox, "resultcheck_sandbox")) {
    stop("Invalid sandbox object. Please provide a sandbox created by setup_sandbox().")
  }
  
  temp_dir <- sandbox$path
  
  # Check if directory exists
  if (!dir.exists(temp_dir)) {
    warning("Sandbox directory does not exist: ", temp_dir)
    return(invisible(FALSE))
  }
  
  # Remove the directory
  tryCatch({
    unlink(temp_dir, recursive = TRUE, force = force)
    
    # Clear from package environment if it's the last sandbox
    if (!is.null(.resultcheck_env$last_sandbox) && 
        identical(.resultcheck_env$last_sandbox$path, temp_dir)) {
      .resultcheck_env$last_sandbox <- NULL
    }
    
    return(invisible(TRUE))
  }, error = function(e) {
    warning("Failed to clean up sandbox directory: ", e$message)
    return(invisible(FALSE))
  })
}


# Package environment to store state
.resultcheck_env <- new.env(parent = emptyenv())
.resultcheck_env$last_sandbox <- NULL
