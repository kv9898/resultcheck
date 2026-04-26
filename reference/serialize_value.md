# Serialize Value to Human-Readable Text

Converts an R object to a human-readable text representation for
snapshots.

## Usage

``` r
serialize_value(value, methods = DEFAULT_SNAPSHOT_METHODS)
```

## Arguments

- value:

  The R object to serialize.

- methods:

  A function or a non-empty list of functions applied in order. Defaults
  to `list(print = base::print, str = utils::str)`.

## Value

A character vector with the text representation.
