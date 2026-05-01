# Detect the calling script name

Tries to identify the script file that is calling snapshot(). Uses
`rstudioapi::getSourceEditorContext()$path` when running in RStudio,
falling back to walking the call stack for source references, and
finally to `"interactive"`.

## Usage

``` r
detect_script_name()
```

## Value

Character string with the detected script basename (without path).
