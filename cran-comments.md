## R CMD check results

0 errors | 0 warnings | 0 notes

## Release summary

This is an update (0.1.4 → 0.2.0) that adds built-in class-based snapshot method defaults, improved script name detection, and fixes two Windows-specific bugs that caused test failures only under `R CMD check` (not via `testthat::test_local()` with pkgload).

## Key changes since 0.1.4

* `snapshot()` and `serialize_value()` now apply built-in class-based method defaults automatically when no explicit `method` argument is provided. Statistical model classes (e.g. `lm`, `glm`, `coxph`, `kmeans`) use `broom::tidy`, `broom::glance`, and/or `broom::augment` when broom is available. If broom is not installed, these defaults are silently skipped and the `print` + `str` fallback is used. User-configured class defaults that reference unavailable packages still raise an error. The full list of supported classes is in `inst/extdata/snapshot-method-defaults.R`.

* `snapshot()` now defaults to both `print` and `str` when no method is specified and no class-based default applies.

* Improved script name detection: `snapshot()` now uses `rstudioapi::getSourceEditorContext()$path` (in RStudio/Positron) as the primary method to detect the calling script name, falling back to a call-stack walk and then `"interactive"`.

* Added "Get Started" vignette covering the typical workflow (project setup, snapshot creation/update, sandbox testing).

* Added FAQ vignette covering common questions (tracking snapshot changes over time, dependency-driven result drift, git integration).

* Fixed a Windows-specific bug in `detect_script_name()` where `normalizePath()` produced backslash separators that did not match the forward-slash paths produced by `dirname()`, causing the call-stack frame filter to never skip package-internal frames. Tests now pass identically on Windows and Linux/macOS.

* Fixed a bug in `with_example()` where reference snapshots were serialized outside the example project directory, causing `find_root()` to fail and skip the built-in class defaults. This produced a method-resolution mismatch between the reference snapshot and the snapshot created by `snapshot()` inside the sandbox.
