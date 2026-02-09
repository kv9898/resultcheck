#' Setup a Sandbox Environment for Testing
#'
#' Creates a temporary directory and copies specified files while preserving
#' their directory structure. This is useful for testing empirical analysis
#' scripts in isolation.
#'
#' @param files Character vector of file paths to copy to the sandbox.
#'   Paths must be relative to the current working directory. Absolute paths
#'   and path traversal attempts (e.g., \code{..}) are rejected for security.
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
#' \dontrun{
#' # Create sandbox and copy files
#' sandbox <- setup_sandbox(c("data/mydata.rds", "code/analysis.R"))
#' 
#' # Use sandbox path
#' print(sandbox$path)
#' 
#' # Clean up when done
#' cleanup_sandbox(sandbox)
#' }
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
  
  # Copy files while preserving directory structure
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
    
    if (!file.exists(file)) {
      warning("File not found, skipping: ", file)
      next
    }
    
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
      file.copy(file, target_path, overwrite = TRUE)
    }, error = function(e) {
      warning("Failed to copy file ", file, ": ", e$message)
    })
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
#' @return Invisible NULL. The function is called for its side effects.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Setup sandbox
#' sandbox <- setup_sandbox(c("data/mydata.rds"))
#' 
#' # Run script in sandbox
#' run_in_sandbox("code/analysis.R", sandbox)
#' 
#' # Clean up
#' cleanup_sandbox(sandbox)
#' }
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
  
  # Check if script exists
  if (!file.exists(script_path)) {
    stop("Script file not found: ", script_path)
  }
  
  # Check if withr is available
  if (!requireNamespace("withr", quietly = TRUE)) {
    stop("Package 'withr' is required but not installed. ",
         "Please install it with: install.packages('withr')")
  }
  
  # Build the execution expression
  exec_expr <- quote(source(script_path))
  
  if (capture_output) {
    exec_expr <- bquote(capture.output(.(exec_expr)))
  }
  
  if (suppress_warnings) {
    exec_expr <- bquote(suppressWarnings(.(exec_expr)))
  }
  
  if (suppress_messages) {
    exec_expr <- bquote(suppressMessages(.(exec_expr)))
  }
  
  # Execute in sandbox directory with graphics suppressed
  tryCatch({
    withr::with_dir(sandbox$path, {
      pdf(NULL)
      eval(exec_expr)
      dev.off()
    })
  }, error = function(e) {
    stop("Error executing script in sandbox: ", e$message)
  })
  
  invisible(NULL)
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
#' \dontrun{
#' # Setup sandbox
#' sandbox <- setup_sandbox(c("data/mydata.rds"))
#' 
#' # ... use sandbox ...
#' 
#' # Clean up
#' cleanup_sandbox(sandbox)
#' }
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
