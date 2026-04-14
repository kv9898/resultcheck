## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Response to CRAN reviewer comments

> If there are references describing the methods in your package, please add
> these in the description field of your DESCRIPTION file in the form
> authors (year) <doi:...>

The package implements an original snapshot-testing workflow for empirical R projects. To the best of our knowledge, there are no published references (papers, preprints, or books) describing these methods. Therefore, no references have been added to the Description field.

> Please replace `\\dontrun{}` wrappers for executable examples and avoid writing
> by default/in examples to the user's home filespace.

Addressed:

* Replaced prior `\dontrun{}` examples with executable examples that run inside
  `with_example()`, which creates and uses a temporary project under `tempdir()`
  and cleans up automatically.
* Added support for empty sandboxes via `setup_sandbox()` (no argument needed),
  and updated examples/docs accordingly.
* Snapshot write path remains configurable through `_resultcheck.yml` via
  `snapshot.dir` (default: `tests/_resultcheck_snaps` under project root).
  In interactive mode, `snapshot()` now warns and shows the exact file path
  before writing/updating snapshot files.
* Interactive mismatch demonstrations remain behind `if (interactive())`.
