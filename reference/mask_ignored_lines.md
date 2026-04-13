# Mask `[ignored]` Lines in New Snapshot Text

Any line in `old_text` that equals `"[ignored]"` (after trimming
whitespace) causes the corresponding line in `new_text` to be replaced
with `"[ignored]"`, so that known-volatile lines never trigger a
snapshot failure. Lines beyond the shorter vector are left unchanged.

## Usage

``` r
mask_ignored_lines(old_text, new_text)
```

## Arguments

- old_text:

  Character vector of the stored snapshot lines.

- new_text:

  Character vector of the freshly generated snapshot lines.

## Value

`new_text` with `[ignored]` substituted at matching positions.

## Details

This helper is used both during comparison (so the lines are skipped)
and when writing an updated snapshot (so the markers are preserved).
