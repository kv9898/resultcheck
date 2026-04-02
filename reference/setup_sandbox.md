# Setup a Sandbox Environment for Testing

Creates a temporary directory and copies specified files and/or
directories into it while preserving their path structure. This is
useful for testing empirical analysis scripts in isolation.

## Usage

``` r
setup_sandbox(files, temp_base = NULL)
```

## Arguments

- files:

  Character vector of relative file or directory paths to copy to the
  sandbox. Paths are resolved relative to the project root (found using
  [`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md));
  if the project root cannot be determined the current working directory
  is used. When a path refers to a directory, the entire directory is
  copied recursively. Absolute paths and path traversal attempts (e.g.,
  `..`) are rejected for security. Snapshot files do *not* need to be
  listed here:
  [`snapshot()`](https://kv9898.github.io/resultcheck/reference/snapshot.md)
  always reads snapshots from the project root, not from the sandbox.

- temp_base:

  Optional. Custom location for the temporary directory. If NULL
  (default), uses [`tempfile()`](https://rdrr.io/r/base/tempfile.html).

## Value

A list with class "resultcheck_sandbox" containing:

- path:

  The path to the created temporary directory

- id:

  A unique timestamp-based identifier for this sandbox

## Examples

``` r
if (FALSE) { # \dontrun{
# Create sandbox and copy files
sandbox <- setup_sandbox(c("data/mydata.rds", "code/analysis.R"))

# Use sandbox path
print(sandbox$path)

# Clean up when done
cleanup_sandbox(sandbox)
} # }
```
