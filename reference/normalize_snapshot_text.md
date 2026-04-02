# Normalize Snapshot Text Before Comparison

Replaces volatile environment representations (for example memory
addresses in `.Environment` attributes) with a stable placeholder so
snapshots remain comparable across different execution contexts.

## Usage

``` r
normalize_snapshot_text(text)
```

## Arguments

- text:

  Character vector with serialized snapshot lines.

## Value

Character vector with normalized snapshot lines.
