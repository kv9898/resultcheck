# Changelog

## resultcheck 0.1.1

- Fixed snapshot inconsistencies caused by variable serialization width
  and directory checks, improving reliability of result comparisons.

## resultcheck 0.1.0

### Initial release

- [`snapshot()`](https://kv9898.github.io/resultcheck/reference/snapshot.md)
  — create and verify human-readable snapshots of R objects (models,
  data frames, tables, vectors, etc.). Interactive mode warns and
  prompts; testing mode (inside
  [`run_in_sandbox()`](https://kv9898.github.io/resultcheck/reference/run_in_sandbox.md))
  errors on mismatch.
- [`setup_sandbox()`](https://kv9898.github.io/resultcheck/reference/setup_sandbox.md)
  — copy project files and/or directories into a temporary directory for
  isolated testing. Accepts individual file paths or entire
  subdirectories.
- [`run_in_sandbox()`](https://kv9898.github.io/resultcheck/reference/run_in_sandbox.md)
  — execute an R script inside the sandbox with the working directory
  set to the sandbox root, while
  [`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md)
  and
  [`snapshot()`](https://kv9898.github.io/resultcheck/reference/snapshot.md)
  transparently resolve back to the original project root.
- [`cleanup_sandbox()`](https://kv9898.github.io/resultcheck/reference/cleanup_sandbox.md)
  — remove the sandbox directory after testing.
- [`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md)
  — locate the project root using `resultcheck.yml`, `.Rproj`, or `.git`
  as markers.
