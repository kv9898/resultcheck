# resultcheck (development version)

* Rename project config file from `resultcheck.yml` to `_resultcheck.yml` (legacy `resultcheck.yml` is still read for backward compatibility).
* Change default snapshot location to `tests/_resultcheck_snaps/` instead of `_resultcheck_snapshots/`.
* Add configurable snapshot directory support via `snapshot.dir` in `_resultcheck.yml`.
* Add `with_example()` to run package examples in temporary projects under `tempdir()`, avoiding writes to user home/package/getwd locations.
* Update examples/docs to be executable without `\\dontrun{}` and use `setup_sandbox()` with no required file arguments for empty sandboxes.
* `snapshot()` now warns with the exact target path before interactive writes; default path remains configurable via `snapshot.dir` in `_resultcheck.yml`.

# resultcheck 0.1.3

* Prepare for release to CRAN.

# resultcheck 0.1.2

* Add precision rounding option in `_resultcheck.yml` to stabilize snapshot comparisons across runs.
* Add `[ignored]` markers in `snapshot()` output to explicitly indicate excluded components.

# resultcheck 0.1.1

* Fixed snapshot inconsistencies caused by variable serialization width and directory checks, improving reliability of result comparisons.
* Added method parameter to snapshot() for print/str/both serialization.

# resultcheck 0.1.0

## Initial release

* `snapshot()` — create and verify human-readable snapshots of R objects
  (models, data frames, tables, vectors, etc.).  Interactive mode warns and
  prompts; testing mode (inside `run_in_sandbox()`) errors on mismatch.
* `setup_sandbox()` — copy project files and/or directories into a temporary
  directory for isolated testing.  Accepts individual file paths or entire
  subdirectories.
* `run_in_sandbox()` — execute an R script inside the sandbox with the working
  directory set to the sandbox root, while `find_root()` and `snapshot()`
  transparently resolve back to the original project root.
* `cleanup_sandbox()` — remove the sandbox directory after testing.
* `find_root()` — locate the project root using `_resultcheck.yml`, `.Rproj`,
  or `.git` as markers.
