# Compare Two Snapshot Values

Compares two serialized snapshots and returns differences.

## Usage

``` r
compare_snapshot_text(old_text, new_text, precision = NULL)
```

## Arguments

- old_text:

  Character vector with old snapshot text.

- new_text:

  Character vector with new snapshot text.

- precision:

  Optional integer. When non-`NULL`, both texts are rounded to this many
  decimal places before comparison (see
  [`round_snapshot_numbers`](https://kv9898.github.io/resultcheck/reference/round_snapshot_numbers.md)).
  Useful for ignoring floating-point noise introduced by platform
  differences.

## Value

A character vector of differences, or NULL if identical.
