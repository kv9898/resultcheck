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

Addressed. Examples no longer write to the user’s home directory and no longer use \dontrun{}.

* Replaced prior `\dontrun{}` examples with executable examples that run inside
  `with_example()`, which creates and uses a temporary project under `tempdir()`
  and cleans up automatically.
* Added support for empty sandboxes via `setup_sandbox()` (no argument needed),
  and updated examples/docs accordingly.
* During examples, all snapshot writes are confined to the temporary project created under `tempdir()`.
* Outside examples, snapshot files are only written in interactive use. In such cases, the user is explicitly notified of the target file path before any write or update occurs.
* The snapshot directory is user-configurable via `_resultcheck.yml` using `snapshot.dir` (default: `tests/_resultcheck_snaps` under the project root).
* Interactive mismatch demonstrations remain behind `if (interactive())`.
