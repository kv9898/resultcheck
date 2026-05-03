# Copilot Instructions for resultcheck

## Overview

`resultcheck` is an R package providing lightweight helpers for checking whether empirical results remain substantively unchanged across code revisions, platform differences, and package updates. Core abstractions:

- **`snapshot()`** — serialises an R object to a human-readable `.md` file and checks it against a previously saved snapshot.
- **`setup_sandbox()` / `run_in_sandbox()` / `cleanup_sandbox()`** — isolate test execution in a temporary directory so file-writing tests stay reproducible.
- **`find_root()`** — locates the project root by searching for `_resultcheck.yml`, `resultcheck.yml` (legacy), `*.Rproj`, or `.git`.
- **`with_example()`** — runs code inside a fully self-contained temporary example project.

## Repository Layout

```
R/                          # Package source
  snapshot.R                # snapshot(), find_root(), serialize_value(), …
  sandbox.R                 # setup_sandbox(), run_in_sandbox(), cleanup_sandbox(), with_example()
  internal.R                # Unexported helpers / package environment
inst/extdata/
  snapshot-method-defaults.R  # Built-in class→method defaults (broom, etc.)
tests/testthat/             # testthat test suite
_resultcheck.yml            # Project root marker + optional config
DESCRIPTION                 # Package metadata and dependencies
NEWS.md                     # Changelog
```

## Development Workflow

### Running tests

```r
R -q -e "testthat::test_local()"
```

All tests should pass; one known sandbox-cleanup warning is expected.

### CRAN-style check (used by CI)

```r
R -q -e "rcmdcheck::rcmdcheck(args = c('--no-manual', '--as-cran'), error_on = 'warning')"
```

### Regenerating documentation

```r
R -q -e "roxygen2::roxygenise()"
```

### Building the package

```r
R CMD build .
```

## Coding Conventions

- **Language**: R. Follow [tidyverse style](https://style.tidyverse.org/) broadly; match the surrounding code style in any file you edit.
- **Documentation**: Every exported function must have a complete roxygen2 block (`@title`, `@description`, `@param`, `@return`, `@export`, `@examples`). Internal helpers use `@keywords internal`.
- **Examples**: Use `with_example({ … })` or `setup_sandbox()` (no required arguments) in examples so they run without writing to the user's working directory. Avoid `\dontrun{}` unless truly necessary.
- **Markdown**: `Roxygen: list(markdown = TRUE)` is set in `DESCRIPTION`, so use backticks and Markdown in roxygen comments.
- **Error messages**: use `stop(…, call. = FALSE)` for user-facing errors; use `warning(…, immediate. = TRUE)` for non-fatal alerts.
- **No new dependencies** without a strong reason. Core imports are `withr`, `rprojroot`, `yaml`. Optional functionality belongs in `Suggests`.

## Configuration

Users configure the package via `_resultcheck.yml` at the project root (legacy: `resultcheck.yml`). Relevant keys:

```yaml
snapshot:
  dir: tests/_resultcheck_snaps   # default snapshot directory
  method: "print+str"             # default serialisation method(s)
  method_by_class:                # per-class overrides
    lm: "broom::tidy+broom::glance"
  method_defaults_file: path/to/custom-defaults.R
  precision: 4                    # optional rounding for numeric stability
```

## Key Behaviours to Preserve

- `snapshot()` **warns** (interactive) or **errors** (inside `run_in_sandbox()`) on mismatch.
- The `both` method token is a **deprecated alias** for `print+str` and emits a warning.
- The `method=` argument accepts only a **function or a non-empty list of functions**; character tokens are rejected (they are only valid in YAML config, resolved internally).
- Built-in class defaults (e.g. `broom::tidy`) are **silently skipped** when `broom` is not installed; user-specified class defaults that reference a missing package still **error**.
- `find_root()` respects the sandbox environment variable to resolve back to the original project root from inside a sandbox.

## Testing Guidelines

- Add tests to the appropriate file under `tests/testthat/`:
  - `test-snapshot.R` — snapshot serialization, comparison, config
  - `test-sandbox.R` — sandbox setup/teardown
  - `test-integration.R` — end-to-end flows
  - `test-example-project.R` — `with_example()` helpers
- Wrap tests that write files inside `withr::with_tempdir()` or use `with_example()` / `setup_sandbox()`.
- Do **not** modify or delete existing tests unless directly fixing a bug in the tested behaviour.

## CI

GitHub Actions workflows live in `.github/workflows/`:

| File | Purpose |
|------|---------|
| `ci-tests.yml` | Runs `rcmdcheck` on macOS, Windows, Ubuntu (release + devel) |
| `copilot-setup-steps.yml` | Pre-installs R and dependencies for the Copilot coding agent |
| `pkgdown.yaml` | Builds and deploys the pkgdown site |
