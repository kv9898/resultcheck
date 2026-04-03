# resultcheck

Result Stability Checks for Empirical R Projects

## Overview

`resultcheck` provides lightweight helpers for checking whether empirical results remain unchanged across code revisions, platform differences, and package updates. Call `snapshot()` on key outputs (models, tables, derived datasets) in your analysis scripts to detect unintended result drift automatically during CI or local testing.

## Installation

```r
# install.packages("devtools")
devtools::install_github("kv9898/resultcheck")
```

## Workflow

The package supports a two-phase workflow:

1. **Interactive development** — run your analysis script and call `snapshot()` on objects you care about. On first run the snapshot is saved as a human-readable `.md` file. On subsequent interactive runs, differences are shown and you are prompted to update.

2. **Automated testing** — wrap your script in `setup_sandbox()` / `run_in_sandbox()` / `cleanup_sandbox()`. Inside `run_in_sandbox()`, `snapshot()` switches to *testing mode*: it errors immediately if a snapshot is missing or has changed, making the test fail.

## Integrated Example

Consider a project with this layout:

```
myproject/
├── resultcheck.yml       # marks the project root
├── data/
│   └── income.csv        # input data
├── analysis.R            # analysis script
└── tests/
    └── testthat/
        └── test-analysis.R
```

### `analysis.R` — snapshot key results and write output

```r
data <- read.csv("data/income.csv")
model <- lm(income ~ age + education, data = data)

# Snapshot detects unexpected result changes across code revisions.
# Interactive: warns and prompts to update when differences are found.
# Inside run_in_sandbox(): errors if snapshot is missing or doesn't match.
resultcheck::snapshot(model, "income_model")

# Write model summary to an output file
dir.create("output", showWarnings = FALSE)
write.csv(
  as.data.frame(coef(summary(model))),
  "output/model_summary.csv"
)
```

### `tests/testthat/test-analysis.R` — automated test

```r
library(testthat)
library(resultcheck)

test_that("analysis produces stable results", {

  # Run the script in an isolated sandbox.
  # Only input data is copied — snapshot files live at the project root and
  # are located automatically by find_root(); you do not need to list them.
  # You may pass an entire directory instead of individual file paths.
  sandbox <- setup_sandbox("data")
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  # Errors immediately if any snapshot inside analysis.R doesn't match.
  run_in_sandbox("analysis.R", sandbox)

  # Verify output files were written.
  expect_true(
    file.exists(file.path(sandbox$path, "output", "model_summary.csv"))
  )
})
```

When `analysis.R` changes in a way that alters the model, `run_in_sandbox()` errors immediately. To accept the change, re-run the script interactively, review the diff, and confirm the update.

---

## Function Reference

### `snapshot(value, name, script_name = NULL, method = c("both", "print", "str"))`

Creates or verifies a snapshot of any R object.

- **First interactive run**: saves the object as a human-readable `.md` file under `_resultcheck_snapshots/<script>/` at the project root.
- **Subsequent interactive runs**: shows a diff and prompts to update.
- **Inside `run_in_sandbox()`**: errors if the snapshot is missing or doesn't match.

The `method` argument controls how the object is serialized:

| Value | Behaviour |
|-------|-----------|
| `"both"` (default) | Type-specific logic using both `print()` and `str()` |
| `"print"` | Only `print()` output is captured |
| `"str"` | Only `str()` output is captured |

Use `"print"` or `"str"` when one serialization method produces volatile output that should be excluded from the snapshot (e.g. objects that embed session-specific file paths or random IDs in their `str()` representation).

Snapshots are plain text and intended to be committed to version control.

### `setup_sandbox(files, temp_base = NULL)`

Creates a temporary directory and copies the listed files and/or directories into it, preserving their path structure relative to the project root. Directories are copied recursively. Snapshot files do not need to be listed.

### `run_in_sandbox(script_path, sandbox = NULL, ...)`

Runs an R script inside the sandbox. The working directory is set to the sandbox, but `find_root()` and `snapshot()` automatically resolve back to the original project root so snapshots are found correctly.

### `cleanup_sandbox(sandbox = NULL, force = TRUE)`

Removes the sandbox directory. Omit the argument to clean up the most recently created sandbox.

### `find_root(start_path = NULL)`

Locates the project root by searching upward for a `resultcheck.yml`, `.Rproj`, or `.git` marker. Called automatically by `snapshot()` and `setup_sandbox()`.

Place an empty `resultcheck.yml` at your project root to make detection reliable:

```yaml
# resultcheck.yml
```

---

## License

MIT © Dianyi Yang
