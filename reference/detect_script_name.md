# Detect the calling script name

Tries to identify the script file that is calling snapshot(). Uses
`QUARTO_DOCUMENT_FILE` during Quarto execution, followed by
[`knitr::current_input()`](https://rdrr.io/pkg/knitr/man/current_input.html)
while a document is being knitted. Otherwise, uses the innermost active
[`source()`](https://rdrr.io/r/base/source.html) or
[`sys.source()`](https://rdrr.io/r/base/sys.source.html) input, followed
by call-stack source references, the active source editor path, and
finally `"interactive"`.

## Usage

``` r
detect_script_name()
```

## Value

Character string with the detected script basename (without path).
