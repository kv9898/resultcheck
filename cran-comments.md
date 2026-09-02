## R CMD check results

0 errors | 0 warnings | 0 notes

## Test environments

* GitHub Actions: Ubuntu (R release and devel)
* GitHub Actions: macOS (R release)
* GitHub Actions: Windows (R release)
* Local: Ubuntu, R 4.6.1

## Release summary

This minor release adds dedicated support for snapshot checks during Quarto
rendering and improves snapshot consistency across rendering contexts.

## Key changes since 0.2.1

* Quarto documents now use their document filename for snapshot storage instead
  of falling back to `"interactive"`.
* Missing snapshots are created automatically during Quarto rendering.
* Snapshot mismatches stop the Quarto render with an informative error.
* Snapshot serialization now uses consistent Unicode formatting across
  interactive sessions and Quarto renders.