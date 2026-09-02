# Detect the calling script name

Tries to identify the script file that is calling snapshot(). Uses
`rstudioapi::getSourceEditorContext()$path` when running in RStudio,
then `QUARTO_DOCUMENT_FILE` during Quarto execution, followed by
[`knitr::current_input()`](https://rdrr.io/pkg/knitr/man/current_input.html)
while a document is being knitted. It falls back to walking the call
stack for source references, and finally to `"interactive"`.

## Usage

``` r
detect_script_name()
```

## Value

Character string with the detected script basename (without path).
