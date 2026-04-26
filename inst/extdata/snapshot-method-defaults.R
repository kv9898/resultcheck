# Built-in class-based snapshot method defaults.
# Define `method_by_class` as a named list where each value is a method
# expression string (for example "summary") or a method spec.
#
# These defaults provide sensible snapshotting methods for common R classes:
# - "print"  : uses the object's print method
# - "str"    : uses str() to show structure
# - "summary": uses summary() (best for statistical models like lm, glm)
# - etc. (any function accessible via name or pkg::name syntax)
method_by_class <- list(
  # Linear models - summary() gives useful coefficients table
  lm         = "summary",
  glm        = "summary",
  aov        = "summary",
  manova     = "summary",

  # Summary objects from models
  "summary.lm"  = "summary",
  "summary.glm" = "summary",

  # Test objects - print gives nice output
  htest       = "print",

  # Data frames and tibbles - str shows structure
  tbl_df      = "str",
  tbl         = "str",
  data.frame  = "str",

  # Matrix/array - str shows dimensions
  matrix      = "str",
  array       = "str"
)