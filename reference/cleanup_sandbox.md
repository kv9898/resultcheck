# Clean Up a Sandbox Environment

Removes a sandbox directory and all its contents. This should be called
after testing is complete to free up disk space.

## Usage

``` r
cleanup_sandbox(sandbox = NULL, force = TRUE)
```

## Arguments

- sandbox:

  Optional. A sandbox object created by
  [`setup_sandbox()`](https://kv9898.github.io/resultcheck/reference/setup_sandbox.md).
  If NULL (default), cleans up the most recently created sandbox.

- force:

  Logical. If TRUE (default), removes directory even if it contains
  files.

## Value

Logical indicating success (invisible).

## Examples

``` r
with_example({
  sandbox <- setup_sandbox()
  cleanup_sandbox(sandbox)
})
```
