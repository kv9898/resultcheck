# Get start path for find_root

Helper function to determine the starting path for find_root(). Checks
for stored sandbox WD first, then falls back to getwd().

## Usage

``` r
get_start_path_for_find_root()
```

## Value

Character path to start searching from
