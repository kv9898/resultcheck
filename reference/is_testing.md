# Detect Testing Context

Determines if code is running in a testing context (sandbox via
run_in_sandbox). This is used to change snapshot() behavior: interactive
mode prompts for updates, while testing mode throws errors on mismatch.

## Usage

``` r
is_testing()
```

## Value

Logical indicating if in testing mode.
