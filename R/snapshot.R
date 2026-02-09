#' Find Project Root Directory
#'
#' Finds the root directory of the current R project using various heuristics.
#' The function searches for markers like \code{resultcheck.yml}, \code{.Rproj} files,
#' or a \code{.git} directory.
#'
#' @param start_path Optional. The directory to start searching from.
#'   If NULL (default), uses the current working directory.
#'
#' @return The path to the project root directory.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' root <- find_root()
#' print(root)
#' }
find_root <- function(start_path = NULL) {
  if (!requireNamespace("rprojroot", quietly = TRUE)) {
    stop("Package 'rprojroot' is required but not installed. ",
         "Please install it with: install.packages('rprojroot')")
  }
  
  if (is.null(start_path)) {
    start_path <- getwd()
  }
  
  # Define criteria for finding project root
  # Try multiple criteria in order of preference
  criteria <- rprojroot::has_file("resultcheck.yml") |
    rprojroot::has_file_pattern("[.]Rproj$") |
    rprojroot::is_git_root
  
  tryCatch({
    root <- rprojroot::find_root(criteria, path = start_path)
    return(root)
  }, error = function(e) {
    stop("Could not find project root. Please ensure you are in a project directory ",
         "with either a resultcheck.yml, .Rproj file, or .git directory.")
  })
}


#' Get Snapshot File Path
#'
#' Constructs the path to a snapshot file within the project's snapshot directory.
#' Snapshot files are stored in \code{_resultcheck_snapshots/} relative to the
#' project root, organized by script name.
#'
#' @param name Character. The name of the snapshot (without extension).
#' @param script_name Optional. The name of the script file creating the snapshot.
#'   If NULL, attempts to detect from the call stack.
#' @param ext Character. The file extension for the snapshot file (default: "md").
#'
#' @return The full path to the snapshot file.
#'
#' @keywords internal
get_snapshot_path <- function(name, script_name = NULL, ext = "md") {
  root <- find_root()
  
  # If script_name not provided, try to detect from call stack
  if (is.null(script_name)) {
    # Get the calling script from the call stack
    for (i in 1:min(10, sys.nframe())) {
      srcref <- getSrcref(sys.call(-i))
      if (!is.null(srcref)) {
        srcfile <- attr(srcref, "srcfile")
        if (!is.null(srcfile) && !is.null(srcfile$filename)) {
          script_name <- basename(srcfile$filename)
          break
        }
      }
    }
    
    # Fallback to "interactive" if we can't detect
    if (is.null(script_name) || script_name == "") {
      script_name <- "interactive"
    }
  }
  
  # Clean up script name (remove extension)
  script_name <- sub("\\.[Rr]$", "", script_name)
  
  # Construct snapshot directory path
  snapshot_dir <- file.path(root, "_resultcheck_snapshots", script_name)
  
  # Create directory if it doesn't exist
  if (!dir.exists(snapshot_dir)) {
    dir.create(snapshot_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Return full path to snapshot file
  snapshot_file <- file.path(snapshot_dir, paste0(name, ".", ext))
  return(snapshot_file)
}


#' Compare Two Values for Snapshot Differences
#'
#' Uses waldo to compare two values and return human-readable differences.
#'
#' @param old The old/expected value.
#' @param new The new/actual value.
#'
#' @return A character vector of differences, or NULL if identical.
#'
#' @keywords internal
compare_snapshot_values <- function(old, new) {
  if (!requireNamespace("waldo", quietly = TRUE)) {
    stop("Package 'waldo' is required but not installed. ",
         "Please install it with: install.packages('waldo')")
  }
  
  comparison <- waldo::compare(old, new, x_arg = "old", y_arg = "new")
  
  if (length(comparison) == 0) {
    return(NULL)
  }
  
  return(as.character(comparison))
}


#' Interactive Snapshot Testing
#'
#' Creates or updates a snapshot of an R object for interactive analysis.
#' On first use, saves the object to a snapshot file. On subsequent uses,
#' compares the current object to the saved snapshot and prompts the user
#' to update if differences are found.
#'
#' Snapshots are stored in \code{_resultcheck_snapshots/} directory relative
#' to the project root, organized by script name.
#'
#' @param value The R object to snapshot (e.g., plot, table, model output).
#' @param name Character. A descriptive name for this snapshot.
#' @param script_name Optional. The name of the script creating the snapshot.
#'   If NULL, attempts to auto-detect from the call stack.
#' @param interactive Logical. Whether to prompt for updates interactively
#'   (default: TRUE). Set to FALSE for non-interactive use.
#'
#' @return Invisible TRUE if snapshot matches or was updated, FALSE otherwise.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # In an analysis script:
#' model <- lm(mpg ~ wt, data = mtcars)
#' snapshot(model, "mtcars_model")
#' 
#' # First time: saves the snapshot
#' # Later times: compares and prompts to update if different
#' 
#' # For non-interactive use (e.g., in automated tests):
#' snapshot(model, "mtcars_model", interactive = FALSE)
#' }
snapshot <- function(value, name, script_name = NULL, interactive = TRUE) {
  if (!requireNamespace("rlang", quietly = TRUE)) {
    stop("Package 'rlang' is required but not installed. ",
         "Please install it with: install.packages('rlang')")
  }
  
  # Get snapshot file path
  snapshot_file <- get_snapshot_path(name, script_name, ext = "rds")
  
  # Check if snapshot exists
  if (!file.exists(snapshot_file)) {
    # First time: save the snapshot
    saveRDS(value, snapshot_file)
    message("New snapshot saved: ", basename(dirname(snapshot_file)), "/", basename(snapshot_file))
    return(invisible(TRUE))
  }
  
  # Load existing snapshot
  old_value <- readRDS(snapshot_file)
  
  # Compare values
  differences <- compare_snapshot_values(old_value, value)
  
  if (is.null(differences)) {
    # No differences - snapshot matches
    message("Snapshot matches: ", name)
    return(invisible(TRUE))
  }
  
  # Differences found
  message("\nSnapshot differences found for: ", name)
  message("File: ", snapshot_file)
  message("\nDifferences:")
  cat(paste(differences, collapse = "\n"), "\n\n")
  
  if (interactive && interactive()) {
    # Prompt user to update
    response <- readline(prompt = "Update snapshot? (y/n): ")
    
    if (tolower(trimws(response)) == "y") {
      saveRDS(value, snapshot_file)
      message("Snapshot updated.")
      return(invisible(TRUE))
    } else {
      message("Snapshot not updated.")
      return(invisible(FALSE))
    }
  } else {
    # Non-interactive mode: don't update, just report
    message("Snapshot differs from saved version. Run interactively to update.")
    return(invisible(FALSE))
  }
}


#' Expect Snapshot Value (for testthat)
#'
#' A testthat expectation that compares a value against a saved snapshot.
#' This is designed for use in automated tests (e.g., within \code{testthat::test_that()}).
#'
#' @param value The R object to compare against the snapshot.
#' @param name Character. The name of the snapshot.
#' @param script_name Optional. The name of the script/test file.
#'   If NULL, attempts to auto-detect from the call stack.
#'
#' @return Invisible NULL. Called for its side effects (expectation).
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(testthat)
#' 
#' test_that("model output is stable", {
#'   model <- lm(mpg ~ wt, data = mtcars)
#'   expect_snapshot_value(model, "mtcars_model")
#' })
#' }
expect_snapshot_value <- function(value, name, script_name = NULL) {
  if (!requireNamespace("testthat", quietly = TRUE)) {
    stop("Package 'testthat' is required but not installed.")
  }
  
  # Get snapshot file path
  snapshot_file <- get_snapshot_path(name, script_name, ext = "rds")
  
  # Check if snapshot exists
  if (!file.exists(snapshot_file)) {
    testthat::fail(paste0(
      "Snapshot does not exist: ", name, "\n",
      "Run interactively first with snapshot() to create it."
    ))
  }
  
  # Load existing snapshot
  old_value <- readRDS(snapshot_file)
  
  # Use testthat's expect_equal for comparison
  testthat::expect_equal(value, old_value, 
                         label = paste0("snapshot: ", name),
                         expected.label = "saved snapshot")
  
  invisible(NULL)
}
