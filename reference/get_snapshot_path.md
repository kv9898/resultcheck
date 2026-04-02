# Get Snapshot File Path

Constructs the path to a snapshot file within the project's snapshot
directory. Snapshot files are stored in `_resultcheck_snapshots/`
relative to the project root, organized by script name.

## Usage

``` r
get_snapshot_path(name, script_name = NULL, ext = "md")
```

## Arguments

- name:

  Character. The name of the snapshot (without extension).

- script_name:

  Optional. The name of the script file creating the snapshot. If NULL,
  attempts to detect from the call stack.

- ext:

  Character. The file extension for the snapshot file (default: "md").

## Value

The full path to the snapshot file.
