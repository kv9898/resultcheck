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
  detects from the active Quarto document or knitr input, then the
  innermost [`source()`](https://rdrr.io/r/base/source.html) or
  [`sys.source()`](https://rdrr.io/r/base/sys.source.html) input,
  call-stack source references, the active source editor, and finally
  `"interactive"`.

- method:

  Optional function or non-empty list of functions used to serialize
  `value`. Functions are executed in order and each section header is
  taken from the method expression or list name. If omitted, method
  defaults are resolved in this order: `snapshot.method_by_class`
  (matched by object class), then `snapshot.method`, then
  `list(print = base::print, str = utils::str)`.

## Value

Invisible TRUE if the snapshot matches, is created, or is updated. In
testing mode, throws an error if the snapshot is missing or doesn't
match. During a Quarto render, throws an error only on mismatch.

## Details

In interactive mode (default), prompts the user to update if differences
are found and emits a warning. In testing mode (inside
[`run_in_sandbox()`](https://kv9898.github.io/resultcheck/reference/run_in_sandbox.md)),
throws an error if a snapshot doesn't exist or doesn't match. During a
Quarto render, missing snapshots are created, while mismatches throw an
error and stop rendering.

Snapshots are stored under `tests/_resultcheck_snaps/` by default,
organized by script name, and configurable via `snapshot.dir` in
`_resultcheck.yml`. Method defaults can be configured via
`snapshot.method` and class-specific defaults via
`snapshot.method_by_class`. Optional class defaults can also be loaded
from an R file using `snapshot.method_defaults_file`. Method strings in
config (for example `"print + str"` or `"stats::coef"`) are resolved to
callable functions. In config expressions, `"+"` is treated as the
method delimiter.

Built-in class defaults (loaded from
inst/extdata/snapshot-method-defaults.R) use broom functions for many
statistical model classes. The default method is typically broom::tidy,
with broom::glance and/or broom::augment added where supported (per the
broom available-methods table at
https://broom.tidymodels.org/articles/available-methods.html).

Set `snapshot.max_print` in the project's `_resultcheck.yml` (or legacy
`resultcheck.yml`) to control base R printing during serialization. The
default is 1000 entries per method, independent of session `max.print`.
Values must be whole numbers from 1 to 2147483647; omitted or null
values use the default. The setting also applies when `method` is
supplied. The caller's options are restored even if a method fails.

Entries are not rows or bytes: a 200-row, seven-column data frame
contains 1400 entries and requires a higher limit, for example
`max_print: 2000`. Base output beyond the limit can be truncated with an
omission notice; changes in omitted values may not be detected. Increase
the limit or select an appropriate summary method. Class-specific
methods, including tibble printing, may use their own limits; custom
methods may explicitly override this setting. Review and regenerate
affected baselines when changing the limit or upgrading from
session-dependent printing.

## Examples

``` r
with_example({
  model <- stats::lm(mpg ~ wt, data = datasets::mtcars)

  # Create a snapshot, then check that the same result matches.
  snapshot(model, "model", script_name = "analysis")
  snapshot(model, "model", script_name = "analysis")

  # Supply a function to snapshot a particular part of the result.
  snapshot(model, "coefficients", script_name = "analysis", method = stats::coef)
})
#> ✓ Snapshot matches: model
#> ✓ Snapshot matches: model
#> ✓ New snapshot saved: analysis/coefficients.md
```
