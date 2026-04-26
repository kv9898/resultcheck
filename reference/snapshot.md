# Interactive Snapshot Testing

Creates or updates a snapshot of an R object for interactive analysis.
On first use, saves the object to a human-readable snapshot file (.md).
On subsequent uses, compares the current object to the saved snapshot.

## Usage

``` r
snapshot(value, name, script_name = NULL, method = NULL)
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

  Optional function or non-empty list of functions used to serialize
  `value`. Functions are executed in order and each section header is
  taken from the method expression or list name. If omitted, method
  defaults are resolved in this order: `snapshot.method_by_class`
  (matched by object class), then `snapshot.method`, then
  `list(print = base::print, str = utils::str)`.

## Value

Invisible TRUE if snapshot matches or was updated. In testing mode,
throws an error if snapshot is missing or doesn't match.

## Details

In interactive mode (default), prompts the user to update if differences
are found and emits a warning. In testing mode (inside testthat or
run_in_sandbox), throws an error if snapshot doesn't exist or doesn't
match.

Snapshots are stored under `tests/_resultcheck_snaps/` by default,
organized by script name, and configurable via `snapshot.dir` in
`_resultcheck.yml`. Method defaults can be configured via
`snapshot.method` and class-specific defaults via
`snapshot.method_by_class`. Optional class defaults can also be loaded
from an R file using `snapshot.method_defaults_file`. Method strings in
config (for example `"print + str"` or `"stats::coef"`) are resolved to
callable functions. In config expressions, `"+"` is treated as the
method delimiter.

## Examples

``` r
with_example({
  model <- stats::lm(mpg ~ wt, data = datasets::mtcars)
  snapshot(model, "model_default", script_name = "analysis")
  snapshot(model, "model_multi", script_name = "analysis",
           method = list(summary = summary, print = print))
  snapshot(model, "model_print", script_name = "analysis", method = print)
  snapshot(model, "model_ns", script_name = "analysis", method = stats::coef)
  snapshot(model, "model_length", script_name = "analysis", method = length)
})
#> ✓ New snapshot saved: analysis/model_default.md
#> ✓ New snapshot saved: analysis/model_multi.md
#> ✓ New snapshot saved: analysis/model_print.md
#> ✓ New snapshot saved: analysis/model_ns.md
#> ✓ New snapshot saved: analysis/model_length.md

with_example({
  sandbox <- setup_sandbox()
  on.exit(cleanup_sandbox(sandbox), add = TRUE)
  run_in_sandbox("analysis.R", sandbox)
})

if (interactive()) with_example({
  sandbox <- setup_sandbox()
  on.exit(cleanup_sandbox(sandbox), add = TRUE)
  run_in_sandbox("analysis.R", sandbox)
}, mismatch = TRUE)
```
