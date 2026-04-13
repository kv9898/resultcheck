# Round Floating-Point Numbers in Snapshot Text

Replaces every floating-point literal (decimal or scientific notation)
found in a character vector of snapshot lines with its value rounded to
`digits` decimal places. Integer literals that contain no decimal point
and no exponent are left untouched, so index ranges such as `[1:1071]`
are never modified.

## Usage

``` r
round_snapshot_numbers(text, digits)
```

## Arguments

- text:

  Character vector of snapshot text lines.

- digits:

  Integer; number of decimal places to keep (passed to
  [`round()`](https://rdrr.io/r/base/Round.html)). Must be a finite
  integer.

## Value

Character vector with floating-point numbers rounded.

## Details

`digits` is passed directly to
[`round`](https://rdrr.io/r/base/Round.html): 0 rounds to the nearest
integer, negative values round to the left of the decimal point.
