# Read resultcheck Configuration

Reads configuration settings from the `resultcheck.yml` file located at
the project root. Returns an empty list if the file does not exist or
cannot be parsed.

## Usage

``` r
read_resultcheck_config()
```

## Value

A named list of configuration values, or an empty list.
