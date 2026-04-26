# Class-Method Default Mapping
#
# This file defines the default snapshotting method for different R classes.
# Users can override this by setting `snapshot: method:` in _resultcheck.yml.
#
# Format: each entry maps a class name to a default method.
#   - "print"  : only print() output
#   - "str"    : only str() output  
#   - "both"   : both print() and str() output (default for unknown classes)
#
# The lookup uses S3 class inheritance: if a value has classes c("foo", "bar"),
# we first check for "foo", then "bar", then fall back to the global default.

.default_class_methods <- list(
  # Linear models and statistical summaries - use print (summary output is more useful)
  "lm"          = "print",
  "glm"         = "print",
  "aov"         = "print",
  "manova"      = "print",
  
  # Model summary objects - use print
  "summary.lm"  = "print",
  "summary.glm" = "print",
  "summary.aov" = "print",
  
  # Tibbles and data frames - str is more informative for structure
  "tbl_df"      = "str",
  "tbl"         = "str",
  "data.frame"  = "str",
  
  # Test objects - print shows results nicely
  "htest"       = "print",
  
  # Matrix and array - str shows dimensions clearly
  "matrix"      = "str",
  "array"       = "str",
  
  # Default for classes not listed above
  "default"     = "both"
)

#' Get Default Snapshot Method for a Class
#'
#' Looks up the appropriate snapshotting method based on the S3 class of
#' an object. Falls back through class inheritance until a match is found.
#'
#' @param value An R object.
#'
#' @return A character string: "print", "str", or "both".
#'
#' @keywords internal
get_default_method_for_class <- function(value) {
  classes <- class(value)
  
  # Handle NULL or atomic vectors without explicit class
  if (length(classes) == 0) {
    return("both")
  }
  
  # Try each class in the inheritance chain
  for (cls in classes) {
    if (cls %in% names(.default_class_methods)) {
      return(.default_class_methods[[cls]])
    }
  }
  
  # Default fallback
  .default_class_methods[["default"]]
}