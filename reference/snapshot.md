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

Snapshots are stored under `tests/_resultcheck_snaps/` by default,
organized by script name, and configurable via `snapshot.dir` in
`_resultcheck.yml`.

## Examples

``` r
with_example({
  model <- stats::lm(mpg ~ wt, data = datasets::mtcars)
  snapshot(model, "model_both", script_name = "analysis", method = "both")
  snapshot(model, "model_print", script_name = "analysis", method = "print")
  snapshot(model, "model_str", script_name = "analysis", method = "str")
})
#> Warning: snapshot() will write a snapshot file to: C:/Users/Dianyi/AppData/Local/Temp/RtmpY953jS/resultcheck-example-4a2b4341b7c89/tests/_resultcheck_snaps/analysis/model_both.md
#> ✓ New snapshot saved: analysis/model_both.md
#> Warning: snapshot() will write a snapshot file to: C:/Users/Dianyi/AppData/Local/Temp/RtmpY953jS/resultcheck-example-4a2b4341b7c89/tests/_resultcheck_snaps/analysis/model_print.md
#> ✓ New snapshot saved: analysis/model_print.md
#> Warning: snapshot() will write a snapshot file to: C:/Users/Dianyi/AppData/Local/Temp/RtmpY953jS/resultcheck-example-4a2b4341b7c89/tests/_resultcheck_snaps/analysis/model_str.md
#> ✓ New snapshot saved: analysis/model_str.md

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
#> Error in value[[3L]](cond): Error executing script in sandbox: 
#> Snapshot differences found for: model
#> File: C:/Users/Dianyi/AppData/Local/Temp/RtmpY953jS/resultcheck-example-4a2b449875615/tests/_resultcheck_snaps/analysis/model.md
#> 
#> Differences:
#> old[1:7] vs new[1:7]
#>   "# Snapshot: lm"
#>   ""
#>   "## List Structure"
#> - "List of 13"
#> + "List of 12"
#>   " $ coefficients : Named num [1:2] 37.29 -5.34"
#>   "  ..- attr(*, \"names\")= chr [1:2] \"(Intercept)\" \"wt\""
#>   " $ residuals    : Named num [1:32] -2.28 -0.92 -2.09 1.3 -0.2 ..."
#> 
#> Snapshot does not match. Run interactively to review and update.
```
