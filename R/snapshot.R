#' Find Project Root Directory
#'
#' Finds the root directory of the current R project using various heuristics.
#' The function searches for markers like \code{resultcheck.yml}, \code{.Rproj} files,
#' or a \code{.git} directory. When running inside a sandbox created by
#' \code{setup_sandbox()}, it will search from the original working directory.
#'
#' @param start_path Optional. The directory to start searching from.
#'   If NULL (default), uses the current working directory or the stored
#'   original working directory if in a sandbox.
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
  
  # Determine start_path if not provided
  if (is.null(start_path)) {
    start_path <- get_start_path_for_find_root()
  }
  
  # Validate and normalize start_path
  if (!dir.exists(start_path)) {
    stop("Start path does not exist: ", start_path, call. = FALSE)
  }
  
  # Normalize the path to avoid issues with rprojroot
  start_path <- normalizePath(start_path, winslash = "/", mustWork = TRUE)
  
  # Define criteria for finding project root
  # Try multiple criteria in order of preference
  criteria <- rprojroot::has_file("resultcheck.yml") |
    rprojroot::has_file_pattern("[.]Rproj$") |
    rprojroot::is_git_root
  
  tryCatch({
    root <- rprojroot::find_root(criteria, path = start_path)
    return(root)
  }, error = function(e) {
    stop("Could not find project root from path: ", start_path, ". ",
         "Please ensure you are in a project directory ",
         "with either a resultcheck.yml, .Rproj file, or .git directory. ",
         "Original error: ", e$message, call. = FALSE)
  })
}


#' Get start path for find_root
#' 
#' Helper function to determine the starting path for find_root().
#' Checks for stored sandbox WD first, then falls back to getwd().
#' 
#' @return Character path to start searching from
#' @keywords internal
get_start_path_for_find_root <- function() {
  # Check if we have a stored original working directory from sandbox
  if (exists(".resultcheck_original_wd", envir = .resultcheck_env)) {
    start_path <- .resultcheck_env$.resultcheck_original_wd
    # Validate the stored path still exists
    if (!is.null(start_path) && dir.exists(start_path)) {
      return(start_path)
    } else if (!is.null(start_path)) {
      warning("Stored original WD no longer exists: ", start_path, 
              ". Falling back to getwd().", immediate. = TRUE)
    }
  }
  
  # Try to get current working directory
  start_path <- tryCatch(getwd(), error = function(e) NULL)
  
  # If getwd() fails or returns NULL
  if (is.null(start_path) || length(start_path) == 0 || start_path == "" || is.na(start_path)) {
    stop("Could not determine current working directory. ",
         "This may happen if the current directory has been deleted. ",
         "Please ensure you are in a valid directory.",
         call. = FALSE)
  }
  
  return(start_path)
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


#' Serialize Value to Human-Readable Text
#'
#' Converts an R object to a human-readable text representation for snapshots.
#'
#' @param value The R object to serialize.
#'
#' @return A character vector with the text representation.
#'
#' @keywords internal
serialize_value <- function(value) {
  # Create a text representation using various methods
  output <- character()
  
  # Add header with object type
  output <- c(output, paste0("# Snapshot: ", class(value)[1]))
  output <- c(output, "")
  
  # Handle different types of objects
  if (is.data.frame(value)) {
    # For data frames, show structure and content
    output <- c(output, "## Structure")
    output <- c(output, utils::capture.output(str(value)))
    output <- c(output, "", "## Data")
    output <- c(output, utils::capture.output(print(value)))
  } else if (inherits(value, "lm") || inherits(value, "glm")) {
    # For models, show summary
    output <- c(output, "## Model Summary")
    output <- c(output, utils::capture.output(summary(value)))
  } else if (is.list(value)) {
    # For lists, use str() for structure
    output <- c(output, "## List Structure")
    output <- c(output, utils::capture.output(str(value)))
  } else if (is.atomic(value)) {
    # For vectors and atomic types
    output <- c(output, "## Value")
    output <- c(output, utils::capture.output(print(value)))
  } else {
    # Default: use print and str
    output <- c(output, "## Object")
    output <- c(output, utils::capture.output(print(value)))
    output <- c(output, "", "## Structure")
    output <- c(output, utils::capture.output(str(value)))
  }
  
  return(output)
}


#' Compare Two Snapshot Values
#'
#' Compares two serialized snapshots and returns differences.
#'
#' @param old_text Character vector with old snapshot text.
#' @param new_text Character vector with new snapshot text.
#'
#' @return A character vector of differences, or NULL if identical.
#'
#' @keywords internal
compare_snapshot_text <- function(old_text, new_text) {
  if (identical(old_text, new_text)) {
    return(NULL)
  }
  
  # Use waldo for comparison if available
  if (requireNamespace("waldo", quietly = TRUE)) {
    comparison <- waldo::compare(old_text, new_text, x_arg = "old", y_arg = "new")
    if (length(comparison) == 0) {
      return(NULL)
    }
    return(as.character(comparison))
  }
  
  # Fallback to basic diff
  output <- character()
  output <- c(output, "Snapshots differ:")
  
  # Show line-by-line differences
  max_len <- max(length(old_text), length(new_text))
  for (i in seq_len(max_len)) {
    old_line <- if (i <= length(old_text)) old_text[i] else "<missing>"
    new_line <- if (i <= length(new_text)) new_text[i] else "<missing>"
    
    if (!identical(old_line, new_line)) {
      output <- c(output, sprintf("Line %d:", i))
      output <- c(output, sprintf("  - %s", old_line))
      output <- c(output, sprintf("  + %s", new_line))
    }
  }
  
  return(output)
}


#' Detect Testing Context
#'
#' Determines if code is running in a testing context (sandbox via run_in_sandbox).
#' This is used to change snapshot() behavior: interactive mode prompts for updates,
#' while testing mode throws errors on mismatch.
#'
#' @return Logical indicating if in testing mode.
#'
#' @keywords internal
is_testing <- function() {
  # Check if we're in a sandbox context by looking at call stack
  # run_in_sandbox stores a flag in the package environment
  in_sandbox <- !is.null(.resultcheck_env$.resultcheck_original_wd)
  
  return(in_sandbox)
}


#' Interactive Snapshot Testing
#'
#' Creates or updates a snapshot of an R object for interactive analysis.
#' On first use, saves the object to a human-readable snapshot file (.md).
#' On subsequent uses, compares the current object to the saved snapshot.
#'
#' In interactive mode (default), prompts the user to update if differences
#' are found and emits a warning. In testing mode (inside testthat or
#' run_in_sandbox), throws an error if snapshot doesn't exist or doesn't match.
#'
#' Snapshots are stored in \code{_resultcheck_snapshots/} directory relative
#' to the project root, organized by script name.
#'
#' @param value The R object to snapshot (e.g., plot, table, model output).
#' @param name Character. A descriptive name for this snapshot.
#' @param script_name Optional. The name of the script creating the snapshot.
#'   If NULL, attempts to auto-detect from the call stack.
#'
#' @return Invisible TRUE if snapshot matches or was updated.
#'   In testing mode, throws an error if snapshot is missing or doesn't match.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # In an analysis script (interactive mode):
#' model <- lm(mpg ~ wt, data = mtcars)
#' snapshot(model, "mtcars_model")
#' 
#' # First time: saves the snapshot
#' # Later times: compares, shows differences, prompts to update
#' 
#' # In testing mode (inside run_in_sandbox or testthat):
#' # Errors if snapshot missing or doesn't match
#' }
snapshot <- function(value, name, script_name = NULL) {
  # Get snapshot file path (.md extension)
  snapshot_file <- get_snapshot_path(name, script_name, ext = "md")
  
  # Serialize the value to text
  new_text <- serialize_value(value)
  
  # Detect if we're in testing mode
  testing_mode <- is_testing()
  
  # Check if snapshot exists
  if (!file.exists(snapshot_file)) {
    if (testing_mode) {
      # In testing mode, error if snapshot doesn't exist
      stop(
        "Snapshot does not exist: ", name, "\n",
        "File: ", snapshot_file, "\n",
        "Run the script interactively first to create snapshots.",
        call. = FALSE
      )
    }
    
    # First time: save the snapshot
    writeLines(new_text, snapshot_file)
    message("\u2713 New snapshot saved: ", basename(dirname(snapshot_file)), "/", basename(snapshot_file))
    return(invisible(TRUE))
  }
  
  # Load existing snapshot
  old_text <- readLines(snapshot_file, warn = FALSE)
  
  # Compare snapshots
  differences <- compare_snapshot_text(old_text, new_text)
  
  if (is.null(differences)) {
    # No differences - snapshot matches
    if (!testing_mode) {
      message("\u2713 Snapshot matches: ", name)
    }
    return(invisible(TRUE))
  }
  
  # Differences found
  diff_msg <- paste0(
    "\nSnapshot differences found for: ", name, "\n",
    "File: ", snapshot_file, "\n\n",
    "Differences:\n",
    paste(differences, collapse = "\n")
  )
  
  if (testing_mode) {
    # In testing mode, throw an error
    stop(diff_msg, "\n\nSnapshot does not match. Run interactively to review and update.", call. = FALSE)
  }
  
  # Interactive mode: show warning and prompt
  warning(diff_msg, call. = FALSE, immediate. = TRUE)
  
  if (interactive()) {
    # Prompt user to update
    cat("\n")
    response <- readline(prompt = "Update snapshot? (y/n): ")
    
    if (tolower(trimws(response)) == "y") {
      writeLines(new_text, snapshot_file)
      message("\u2713 Snapshot updated.")
      return(invisible(TRUE))
    } else {
      message("\u2717 Snapshot not updated.")
      return(invisible(FALSE))
    }
  } else {
    # Non-interactive but not testing - just warn
    message("\n\u26a0 Run interactively to update snapshot.")
    return(invisible(FALSE))
  }
}

