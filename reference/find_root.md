# Find Project Root Directory

Finds the root directory of the current R project using various
heuristics. The function searches for markers like `_resultcheck.yml`
(preferred), `resultcheck.yml` (legacy), `.Rproj` files, or a `.git`
directory. When running inside a sandbox created by
[`setup_sandbox()`](https://kv9898.github.io/resultcheck/reference/setup_sandbox.md),
it will search from the original working directory.

## Usage

``` r
find_root(start_path = NULL)
```

## Arguments

- start_path:

  Optional. The directory to start searching from. If NULL (default),
  uses the current working directory or the stored original working
  directory if in a sandbox.

## Value

The path to the project root directory.

## Examples

``` r
with_example({
  root <- find_root()
  print(root)
})
#> [1] "/tmp/RtmpjMm93j/resultcheck-example-193c4db85c89"
```
