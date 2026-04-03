# Serialize Value to Human-Readable Text

Converts an R object to a human-readable text representation for
snapshots.

## Usage

``` r
serialize_value(value, method = c("both", "print", "str"))
```

## Arguments

- value:

  The R object to serialize.

- method:

  Character. Controls which serialization method(s) are used. `"both"`
  (default) uses both [`print()`](https://rdrr.io/r/base/print.html) and
  [`str()`](https://rdrr.io/r/utils/str.html). `"print"` uses only
  [`print()`](https://rdrr.io/r/base/print.html). `"str"` uses only
  [`str()`](https://rdrr.io/r/utils/str.html).

## Value

A character vector with the text representation.
