# resultcheck 0.1.2

* Add precision rounding option in `resultcheck.yml` to stabilise snapshot comparisons across runs.
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
* `find_root()` — locate the project root using `resultcheck.yml`, `.Rproj`,
  or `.git` as markers.
