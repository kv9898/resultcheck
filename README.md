# resultcheck

<!-- badges: start -->

[![R-CMD_CI_Tests_Badge](https://github.com/kv9898/resultcheck/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/kv9898/resultcheck/actions/workflows/ci-tests.yml)
[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/resultcheck)](https://cran.r-project.org/package=resultcheck)
[![CRAN_Downloads_Badge](https://cranlogs.r-pkg.org/badges/resultcheck)](https://cran.r-project.org/package=resultcheck)

<!-- badges: end -->

Result Stability Checks for Empirical R Projects

## Overview

`resultcheck` provides lightweight helpers for checking whether empirical results remain unchanged across code revisions, platform differences, and package updates. Call `snapshot()` on key outputs (models, tables, derived datasets) in your analysis scripts to detect unintended result drift automatically during CI or local testing.

## Installation

### Latest Stable Version

```r
install.packages("resultcheck")
```

### Latest Development Version (Unstable)

```r
# install.packages("devtools")
devtools::install_github("kv9898/resultcheck")
```

## Workflow

The package supports a two-phase workflow:

1. **Interactive development** — run your analysis script and call `snapshot()` on objects you care about. On first run the snapshot is saved as a human-readable `.md` file. On subsequent interactive runs, differences are shown and you are prompted to update.

2. **Automated testing** — wrap your script in `setup_sandbox()` / `run_in_sandbox()` / `cleanup_sandbox()`. Inside `run_in_sandbox()`, `snapshot()` switches to *testing mode*: it errors immediately if a snapshot is missing or has changed, making the test fail.

## Integrated Example

`with_example()` can generate this layout for documentation/testing under `tempdir()`:

```
myproject/
├── _resultcheck.yml
├── analysis.R
└── tests/
    ├── _resultcheck_snaps/
    │   └── analysis/
    │       ├── model.md
    │       └── model_mismatch.md
    └── testthat/
        └── test-analysis.R
```

### `analysis.R` — snapshot key results

```r
model <- lm(mpg ~ wt, data = mtcars)
resultcheck::snapshot(model, "model")
```

### `tests/testthat/test-analysis.R` — automated test

```r
library(testthat)
library(resultcheck)

test_that("analysis produces stable results", {
  sandbox <- setup_sandbox()
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  expect_true(run_in_sandbox("analysis.R", sandbox))
})
```

To try this quickly without creating files in your current project:

```r
resultcheck::with_example({
  sandbox <- setup_sandbox()
  on.exit(cleanup_sandbox(sandbox), add = TRUE)
  stopifnot(isTRUE(run_in_sandbox("analysis.R", sandbox)))
})
```

---

## Function Reference

### `snapshot(value, name, script_name = NULL, method = c("both", "print", "str"))`

Creates or verifies a snapshot of any R object.

- **First interactive run**: saves the object as a human-readable `.md` file under `tests/_resultcheck_snaps/<script>/` at the project root by default.
- **Subsequent interactive runs**: shows a diff and prompts to update.
- **Inside `run_in_sandbox()`**: errors if the snapshot is missing or doesn't match.
- **When writing snapshots interactively**: warns and shows the exact output path.

You can override the default snapshot directory in `_resultcheck.yml`:

```yaml
snapshot:
  dir: "custom/snapshots/path"
```

The `method` argument controls how the object is serialized:

| Value | Behavior |
|-------|-----------|
| `"both"` (default) | Type-specific logic using both `print()` and `str()` |
| `"print"` | Only `print()` output is captured |
| `"str"` | Only `str()` output is captured |

Use `"print"` or `"str"` when one serialization method produces volatile output that should be excluded from the snapshot (e.g. objects that embed session-specific file paths or random IDs in their `str()` representation).

Snapshots are plain text and intended to be committed to version control.

### `setup_sandbox(files = NULL, temp_base = NULL)`

Creates a temporary directory and copies the listed files and/or directories into it, preserving their path structure relative to the project root. Directories are copied recursively. Snapshot files do not need to be listed.

### `run_in_sandbox(script_path, sandbox = NULL, ...)`

Runs an R script inside the sandbox. The working directory is set to the sandbox, but `find_root()` and `snapshot()` automatically resolve back to the original project root so snapshots are found correctly.

Returns `TRUE` invisibly on success, so you can use `expect_true(run_in_sandbox(...))` directly in testthat.

### `cleanup_sandbox(sandbox = NULL, force = TRUE)`

Removes the sandbox directory. Omit the argument to clean up the most recently created sandbox.

### `find_root(start_path = NULL)`

Locates the project root by searching upward for a `_resultcheck.yml` (or legacy `resultcheck.yml`), `.Rproj`, or `.git` marker. Called automatically by `snapshot()` and `setup_sandbox()`.

Place an empty `_resultcheck.yml` at your project root to make detection reliable:

```yaml
# _resultcheck.yml
```

### `with_example(code, mismatch = FALSE)`

Creates a temporary example project in `tempdir()`, sets the working directory there while evaluating `code`, then cleans up automatically.

---

## License

MIT © Dianyi Yang
