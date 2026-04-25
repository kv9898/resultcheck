# Run Code Inside a Temporary Example Project

Creates a self-contained example project under
[`tempdir()`](https://rdrr.io/r/base/tempfile.html), including:

- `_resultcheck.yml` (project root marker)

- `analysis.R` with `snapshot(model, "model")`

- matching and mismatched snapshot files

- `tests/testthat/test-analysis.R`

then temporarily sets the working directory to that project while
evaluating `code`.

## Usage

``` r
with_example(code, mismatch = FALSE)
```

## Arguments

- code:

  Code to evaluate inside the temporary example project.

- mismatch:

  Logical. If TRUE, replaces the active snapshot with a mismatched
  version before evaluating `code`.

## Value

The value of `code`.

## Examples

``` r
with_example({
  root <- find_root()
  print(root)
})
#> [1] "/tmp/RtmphXcOGP/resultcheck-example-193e522f1102"
```
