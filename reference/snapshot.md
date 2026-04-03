# Interactive Snapshot Testing

Creates or updates a snapshot of an R object for interactive analysis.
On first use, saves the object to a human-readable snapshot file (.md).
On subsequent uses, compares the current object to the saved snapshot.

## Usage

``` r
snapshot(value, name, script_name = NULL, method = c("both", "print", "str"))
```

## Arguments

- value:

  The R object to snapshot (e.g., plot, table, model output).

- name:

  Character. A descriptive name for this snapshot.

- script_name:

  Optional. The name of the script creating the snapshot. If NULL,
  attempts to auto-detect from the call stack.

- method:

  Character. Controls which serialization method(s) are used when
  capturing the snapshot. `"both"` (default) applies type-specific logic
  that uses both [`print()`](https://rdrr.io/r/base/print.html) and
  [`str()`](https://rdrr.io/r/utils/str.html). `"print"` uses only
  [`print()`](https://rdrr.io/r/base/print.html), and `"str"` uses only
  [`str()`](https://rdrr.io/r/utils/str.html). Use `"print"` or `"str"`
  when one of the methods produces volatile output that should be
  excluded from the snapshot (e.g. objects that embed session-specific
  paths or IDs in their [`str()`](https://rdrr.io/r/utils/str.html)
  representation).

## Value

Invisible TRUE if snapshot matches or was updated. In testing mode,
throws an error if snapshot is missing or doesn't match.

## Details

In interactive mode (default), prompts the user to update if differences
are found and emits a warning. In testing mode (inside testthat or
run_in_sandbox), throws an error if snapshot doesn't exist or doesn't
match.

Snapshots are stored in `_resultcheck_snapshots/` directory relative to
the project root, organized by script name.

## Examples

``` r
if (FALSE) { # \dontrun{
# In an analysis script (interactive mode):
model <- lm(mpg ~ wt, data = mtcars)
snapshot(model, "mtcars_model")

# First time: saves the snapshot
# Later times: compares, shows differences, prompts to update

# Use only print() output (skip str() which may contain volatile fields):
snapshot(model, "mtcars_model_print", method = "print")

# Use only str() output:
snapshot(model, "mtcars_model_str", method = "str")

# In testing mode (inside run_in_sandbox or testthat):
# Errors if snapshot missing or doesn't match
} # }
```
