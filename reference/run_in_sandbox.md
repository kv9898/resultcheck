# Run Code in a Sandbox Environment

Executes an R script within a sandbox directory, suppressing messages,
warnings, and graphical output. This is useful for testing empirical
analysis scripts without polluting the console or creating unwanted
plots.

## Usage

``` r
run_in_sandbox(
  script_path,
  sandbox = NULL,
  suppress_messages = TRUE,
  suppress_warnings = TRUE,
  capture_output = TRUE
)
```

## Arguments

- script_path:

  Path to the R script to execute.

- sandbox:

  Optional. A sandbox object created by
  [`setup_sandbox()`](https://kv9898.github.io/resultcheck/reference/setup_sandbox.md).
  If NULL (default), uses the most recently created sandbox.

- suppress_messages:

  Logical. Whether to suppress messages (default: TRUE).

- suppress_warnings:

  Logical. Whether to suppress warnings (default: TRUE).

- capture_output:

  Logical. Whether to capture output (default: TRUE).

## Value

Invisible NULL. The function is called for its side effects.

## Examples

``` r
if (FALSE) { # \dontrun{
# Setup sandbox
sandbox <- setup_sandbox(c("data/mydata.rds", "code/analysis.R"))

# Run script in sandbox
run_in_sandbox("code/analysis.R", sandbox)

# Clean up
cleanup_sandbox(sandbox)
} # }
```
