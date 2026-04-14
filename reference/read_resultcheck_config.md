# Read resultcheck Configuration

Reads configuration settings from the `_resultcheck.yml` file located at
the project root (falling back to legacy `resultcheck.yml` if needed).
Returns an empty list if neither file exists or parsing fails.

## Usage

``` r
read_resultcheck_config()
```

## Value

A named list of configuration values, or an empty list.
