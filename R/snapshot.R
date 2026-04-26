#' Find Project Root Directory
#'
#' Finds the root directory of the current R project using various heuristics.
#' The function searches for markers like \code{_resultcheck.yml} (preferred),
#' \code{resultcheck.yml} (legacy), \code{.Rproj} files,
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
#' with_example({
#'   root <- find_root()
#'   print(root)
#' })
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
  criteria <- rprojroot::has_file("_resultcheck.yml") |
    rprojroot::has_file("resultcheck.yml") |
    rprojroot::has_file_pattern("[.]Rproj$") |
    rprojroot::is_git_root
  
  tryCatch({
    root <- rprojroot::find_root(criteria, path = start_path)
    return(root)
  }, error = function(e) {
    stop("Could not find project root from path: ", start_path, ". ",
         "Please ensure you are in a project directory ",
         "with either a _resultcheck.yml (or legacy resultcheck.yml), ",
         ".Rproj file, or .git directory. ",
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
#' Snapshot files are stored under \code{tests/_resultcheck_snaps/} by default,
#' organized by script name. This location can be overridden with
#' \code{snapshot.dir} in \code{_resultcheck.yml}.
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
  config <- read_resultcheck_config()
  
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
  
  snapshot_base <- config[["snapshot"]][["dir"]]
  if (!is.character(snapshot_base) ||
      length(snapshot_base) != 1L ||
      is.na(snapshot_base) ||
      trimws(snapshot_base) == "") {
    snapshot_base <- "tests/_resultcheck_snaps"
  }
  snapshot_base <- trimws(snapshot_base)
  is_absolute <- startsWith(snapshot_base, "/") ||
    grepl("^[A-Za-z]:[/\\\\]", snapshot_base)
  snapshot_root <- if (is_absolute) snapshot_base else file.path(root, snapshot_base)

  # Construct snapshot directory path
  snapshot_dir <- file.path(snapshot_root, script_name)
  
  # Create directory if it doesn't exist
  if (!dir.exists(snapshot_dir)) {
    dir.create(snapshot_dir, recursive = TRUE, showWarnings = FALSE)
  }
  
  # Return full path to snapshot file
  snapshot_file <- file.path(snapshot_dir, paste0(name, ".", ext))
  return(snapshot_file)
}


# Marker string that users can place on any line of a snapshot file to indicate
# that the line's value is known to vary across platforms and should be ignored
# during comparison.  The entire line must consist of exactly this string.
IGNORED_MARKER <- "[ignored]"


#' Read resultcheck Configuration
#'
#' Reads configuration settings from the \code{_resultcheck.yml} file located
#' at the project root (falling back to legacy \code{resultcheck.yml} if
#' needed). Returns an empty list if neither file exists or parsing fails.
#'
#' @return A named list of configuration values, or an empty list.
#'
#' @keywords internal
read_resultcheck_config <- function() {
  tryCatch({
    root <- find_root()
    config_path <- file.path(root, "_resultcheck.yml")
    if (!file.exists(config_path)) {
      legacy_path <- file.path(root, "resultcheck.yml")
      config_path <- if (file.exists(legacy_path)) legacy_path else config_path
    }
    if (!file.exists(config_path)) return(list())
    config <- yaml::read_yaml(config_path)
    if (is.null(config)) {
      config <- list()
    }
    config[["snapshot"]] <- normalize_snapshot_config(config[["snapshot"]], root = root)
    config
  }, error = function(e) list())
}


DEFAULT_SNAPSHOT_METHODS <- list(
  print = base::print,
  str = utils::str
)

normalize_snapshot_config <- function(snapshot_cfg, root) {
  if (is.null(snapshot_cfg)) {
    return(list())
  }
  if (!is.list(snapshot_cfg)) {
    stop("`snapshot` configuration must be a list.", call. = FALSE)
  }
  cfg <- snapshot_cfg
  cfg[["method"]] <- NULL
  cfg[["method_by_class"]] <- NULL
  cfg[["method_defaults_file"]] <- NULL
  cfg
}

extract_method_labels_from_expr <- function(method_expr) {
  if (missing(method_expr) || is.null(method_expr)) {
    return(NULL)
  }
  if (is.symbol(method_expr)) {
    return(as.character(method_expr))
  }
  if (is.call(method_expr) && as.character(method_expr[[1L]]) %in% c("c", "list")) {
    args <- as.list(method_expr)[-1L]
    return(vapply(args, function(arg) paste(deparse(arg), collapse = ""), character(1L)))
  }
  NULL
}

coerce_snapshot_methods <- function(method,
                                    arg_name = "method",
                                    method_expr = NULL) {
  is_method_spec <- is.list(method) &&
    length(method) > 0L &&
    all(vapply(method, function(x) {
      is.list(x) &&
        is.function(x[["fn"]]) &&
        is.character(x[["label"]]) &&
        length(x[["label"]]) == 1L
    }, logical(1L)))
  if (is_method_spec) {
    return(method)
  }

  method_list <- if (is.function(method)) {
    list(method)
  } else if (is.list(method) && length(method) > 0L && all(vapply(method, is.function, logical(1L)))) {
    method
  } else {
    stop("`", arg_name, "` must be a function or a non-empty list of functions.", call. = FALSE)
  }

  labels <- names(method_list)
  if (is.null(labels)) {
    labels <- rep("", length(method_list))
  }

  expr_labels <- extract_method_labels_from_expr(method_expr)
  if (!is.null(expr_labels) && length(expr_labels) == length(method_list)) {
    missing_idx <- which(trimws(labels) == "")
    if (length(missing_idx) > 0L) {
      labels[missing_idx] <- expr_labels[missing_idx]
    }
  }

  guess_function_name <- function(fn) {
    envs <- c(list(globalenv()), lapply(search(), as.environment), list(baseenv()))
    for (env in envs) {
      nms <- tryCatch(ls(env, all.names = TRUE), error = function(e) character())
      for (nm in nms) {
        obj <- tryCatch(get(nm, envir = env, inherits = FALSE), error = function(e) NULL)
        if (is.function(obj) && identical(obj, fn)) {
          return(nm)
        }
      }
    }
    NULL
  }

  guessed <- vapply(method_list, function(fn) {
    nm <- guess_function_name(fn)
    if (is.null(nm)) "" else nm
  }, character(1L))
  fill_guess <- which(trimws(labels) == "" & nzchar(guessed))
  if (length(fill_guess) > 0L) {
    labels[fill_guess] <- guessed[fill_guess]
  }

  missing_labels <- which(trimws(labels) == "")
  if (length(missing_labels) > 0L) {
    labels[missing_labels] <- paste0("method_", missing_labels)
  }

  Map(function(fn, label) {
    list(fn = fn, label = label)
  }, method_list, labels)
}

resolve_snapshot_methods <- function(value, method, config, method_missing, method_expr = NULL) {
  if (!isTRUE(method_missing)) {
    return(coerce_snapshot_methods(method, arg_name = "method", method_expr = method_expr))
  }
  coerce_snapshot_methods(DEFAULT_SNAPSHOT_METHODS, arg_name = "method")
}


#' Round Floating-Point Numbers in Snapshot Text
#'
#' Replaces every floating-point literal (decimal or scientific notation) found
#' in a character vector of snapshot lines with its value rounded to
#' \code{digits} decimal places.  Integer literals that contain no decimal
#' point and no exponent are left untouched, so index ranges such as
#' \code{[1:1071]} are never modified.
#'
#' \code{digits} is passed directly to \code{\link[base]{round}}: 0 rounds to
#' the nearest integer, negative values round to the left of the decimal point.
#'
#' @param text   Character vector of snapshot text lines.
#' @param digits Integer; number of decimal places to keep (passed to
#'   \code{round()}).  Must be a finite integer.
#'
#' @return Character vector with floating-point numbers rounded.
#'
#' @keywords internal
round_snapshot_numbers <- function(text, digits) {
  # Two alternatives, both require a decimal point or exponent so that pure
  # integers (e.g. index ranges like 1071) are never matched:
  #   1. A number WITH a decimal point, optionally followed by an exponent.
  #      Examples: 1.22   -0.423   2.41e-17   +1.0E+3
  #   2. An integer written in scientific notation (no decimal point required).
  #      Examples: 1e+07   -2E4
  pattern <- "[-+]?[0-9]*\\.[0-9]+([eE][-+]?[0-9]+)?|[-+]?[0-9]+[eE][-+]?[0-9]+"

  vapply(text, function(line) {
    m <- gregexpr(pattern, line, perl = TRUE)[[1]]
    if (m[1] == -1L) return(line)

    match_lengths <- attr(m, "match.length")
    parts <- character(length(m) * 2L + 1L)
    pos   <- 1L
    j     <- 1L

    for (i in seq_along(m)) {
      start <- m[i]
      end   <- start + match_lengths[i] - 1L

      parts[j] <- substr(line, pos, start - 1L)
      j <- j + 1L

      num_str <- substr(line, start, end)
      # The regex guarantees the matched string looks like a number; any failure
      # to parse (e.g. an NA) is treated as a non-match and the original token
      # is kept.  suppressWarnings avoids noisy NAs-introduced messages.
      num_val <- suppressWarnings(as.numeric(num_str))
      parts[j] <- if (!is.na(num_val)) {
        as.character(round(num_val, digits))
      } else {
        num_str
      }
      j   <- j + 1L
      pos <- end + 1L
    }

    parts[j] <- substr(line, pos, nchar(line))
    paste(parts[seq_len(j)], collapse = "")
  }, character(1L), USE.NAMES = FALSE)
}


#' Mask \code{[ignored]} Lines in New Snapshot Text
#'
#' Any line in \code{old_text} that equals \code{"[ignored]"} (after trimming
#' whitespace) causes the corresponding line in \code{new_text} to be replaced
#' with \code{"[ignored]"}, so that known-volatile lines never trigger a
#' snapshot failure.  Lines beyond the shorter vector are left unchanged.
#'
#' This helper is used both during comparison (so the lines are skipped) and
#' when writing an updated snapshot (so the markers are preserved).
#'
#' @param old_text Character vector of the stored snapshot lines.
#' @param new_text Character vector of the freshly generated snapshot lines.
#'
#' @return \code{new_text} with \code{[ignored]} substituted at matching
#'   positions.
#'
#' @keywords internal
mask_ignored_lines <- function(old_text, new_text) {
  min_len <- min(length(old_text), length(new_text))
  for (i in seq_len(min_len)) {
    if (trimws(old_text[i]) == IGNORED_MARKER) {
      new_text[i] <- IGNORED_MARKER
    }
  }
  new_text
}


# Fixed console width used when capturing snapshot output to ensure consistent,
# fully-untruncated output regardless of the R session's current width setting.
# The value is intentionally very large so that str() and print() never wrap
# or abbreviate values mid-line, keeping snapshot text deterministic across
# machines and environments.
SNAPSHOT_OUTPUT_WIDTH <- 110L

#' Serialize Value to Human-Readable Text
#'
#' Converts an R object to a human-readable text representation for snapshots.
#'
#' @param value The R object to serialize.
#' @param methods A function or a non-empty list of functions applied in order.
#'   Defaults to \code{list(print = base::print, str = utils::str)}.
#' 
#' @return A character vector with the text representation.
#'
#' @keywords internal
serialize_value <- function(value, methods = DEFAULT_SNAPSHOT_METHODS) {
  methods <- coerce_snapshot_methods(methods, arg_name = "methods")
  # Create a text representation using various methods
  output <- character()
  
  # Add header with object type
  output <- c(output, paste0("# Snapshot: ", class(value)[1]))
  output <- c(output, "")
  
  # Use a fixed large width so that snapshot output is consistent regardless
  # of the R session's console width setting.
  withr::with_options(list(width = SNAPSHOT_OUTPUT_WIDTH, pillar.advice = TRUE), {
    first_method <- TRUE
    for (method_def in methods) {
      section <- tryCatch(
        utils::capture.output(method_def$fn(value)),
        error = function(e) {
          obj_class <- class(value)
          if (length(obj_class) == 0L) obj_class <- as.character(typeof(value))
          stop(
            "Snapshot method `", method_def$label, "` is not available for class `",
            obj_class[1L], "`: ", conditionMessage(e),
            call. = FALSE
          )
        }
      )

      if (!first_method) {
        output <- c(output, "")
      }
      output <- c(output, paste0("## ", method_def$label))
      output <- c(output, section)
      first_method <- FALSE
    }
  })
  
  return(output)
}


#' Compare Two Snapshot Values
#'
#' Compares two serialized snapshots and returns differences.
#'
#' @param old_text  Character vector with old snapshot text.
#' @param new_text  Character vector with new snapshot text.
#' @param precision Optional integer.  When non-\code{NULL}, both texts are
#'   rounded to this many decimal places before comparison (see
#'   \code{\link{round_snapshot_numbers}}).  Useful for ignoring
#'   floating-point noise introduced by platform differences.
#'
#' @return A character vector of differences, or NULL if identical.
#'
#' @keywords internal
compare_snapshot_text <- function(old_text, new_text, precision = NULL) {
  old_text <- normalize_snapshot_text(old_text)
  new_text <- normalize_snapshot_text(new_text)

  # Apply numeric precision rounding when configured
  if (!is.null(precision)) {
    old_text <- round_snapshot_numbers(old_text, as.integer(precision))
    new_text <- round_snapshot_numbers(new_text, as.integer(precision))
  }

  # Mask lines that the user has marked as [ignored] in the stored snapshot
  new_text <- mask_ignored_lines(old_text, new_text)

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


#' Normalize Snapshot Text Before Comparison
#'
#' Replaces volatile environment representations (for example memory addresses
#' in `.Environment` attributes) with a stable placeholder so snapshots remain
#' comparable across different execution contexts.
#'
#' @param text Character vector with serialized snapshot lines.
#'
#' @return Character vector with normalized snapshot lines.
#'
#' @keywords internal
normalize_snapshot_text <- function(text) {
  gsub(
    '(<environment: )[^>]+(>[[:space:]]*)$',
    '\\1<normalized>\\2',
    text
  )
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

warn_snapshot_write <- function(snapshot_file) {
  if (interactive()) {
    warning("snapshot() will write a snapshot file to: ", snapshot_file,
            call. = FALSE, immediate. = TRUE)
  }
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
#' Snapshots are stored under \code{tests/_resultcheck_snaps/} by default,
#' organized by script name, and configurable via \code{snapshot.dir} in
#' \code{_resultcheck.yml}.
#'
#' @param value The R object to snapshot (e.g., plot, table, model output).
#' @param name Character. A descriptive name for this snapshot.
#' @param script_name Optional. The name of the script creating the snapshot.
#'   If NULL, attempts to auto-detect from the call stack.
#' @param method Optional function or non-empty list of functions used to
#'   serialize \code{value}. Functions are executed in order and each section
#'   header is taken from the method expression or list name. If omitted,
#'   defaults to \code{list(print = base::print, str = utils::str)}.
#'
#' @return Invisible TRUE if snapshot matches or was updated.
#'   In testing mode, throws an error if snapshot is missing or doesn't match.
#'
#' @export
#'
#' @examples
#' with_example({
#'   model <- stats::lm(mpg ~ wt, data = datasets::mtcars)
#'   snapshot(model, "model_default", script_name = "analysis")
#'   snapshot(model, "model_multi", script_name = "analysis",
#'            method = list(summary = summary, print = print))
#'   snapshot(model, "model_print", script_name = "analysis", method = print)
#'   snapshot(model, "model_length", script_name = "analysis", method = length)
#' })
#'
#' with_example({
#'   sandbox <- setup_sandbox()
#'   on.exit(cleanup_sandbox(sandbox), add = TRUE)
#'   run_in_sandbox("analysis.R", sandbox)
#' })
#'
#' if (interactive()) with_example({
#'   sandbox <- setup_sandbox()
#'   on.exit(cleanup_sandbox(sandbox), add = TRUE)
#'   run_in_sandbox("analysis.R", sandbox)
#' }, mismatch = TRUE)
snapshot <- function(value, name, script_name = NULL, method = NULL) {
  # Get snapshot file path (.md extension)
  snapshot_file <- get_snapshot_path(name, script_name, ext = "md")
  
  # Read project configuration for optional precision rounding
  config    <- read_resultcheck_config()
  precision <- config[["snapshot"]][["precision"]]
  methods <- resolve_snapshot_methods(
    value = value,
    method = method,
    config = config,
    method_missing = missing(method),
    method_expr = if (!missing(method)) substitute(method) else NULL
  )

  # Serialize the value to text
  new_text <- serialize_value(value, methods = methods)
  new_text <- normalize_snapshot_text(new_text)

  if (!is.null(precision)) {
    new_text <- round_snapshot_numbers(new_text, as.integer(precision))
  }
  
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
    warn_snapshot_write(snapshot_file)
    writeLines(new_text, snapshot_file)
    message("\u2713 New snapshot saved: ", basename(dirname(snapshot_file)), "/", basename(snapshot_file))
    return(invisible(TRUE))
  }
  
  # Load existing snapshot
  old_text <- readLines(snapshot_file, warn = FALSE)
  
  # Compare snapshots (precision already applied to new_text above; also
  # applied to old_text inside compare_snapshot_text for backward compatibility
  # with snapshots stored before precision was configured).
  differences <- compare_snapshot_text(old_text, new_text, precision = precision)
  
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
      # Preserve any [ignored] markers from the stored snapshot
      warn_snapshot_write(snapshot_file)
      writeLines(mask_ignored_lines(old_text, new_text), snapshot_file)
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
