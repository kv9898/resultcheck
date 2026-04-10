## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Response to CRAN reviewer comments

> If there are references describing the methods in your package, please add
> these in the description field of your DESCRIPTION file in the form
> authors (year) <doi:...>

The package implements an original snapshot-testing workflow for empirical R
projects. There are no external publications (papers, preprints, or book
chapters) that describe the methods used in this package. No references have
therefore been added to the Description field.

> Please replace \dontrun{} with \donttest{}, use if(interactive()){} for
> interactive examples, and ensure examples do not write to user filespace.

All `\dontrun{}` wrappers in examples have been replaced with `\donttest{}`.

Examples that write files (e.g. `snapshot()`, `setup_sandbox()`,
`run_in_sandbox()`, `cleanup_sandbox()`) now create a temporary directory
(via `tempfile()` / `dir.create()`) as a self-contained project root and use
`withr::with_dir()` to run within it. All file I/O therefore stays inside
`tempdir()`, not in the user's working directory or home directory. The
temporary directory is removed with `unlink()` at the end of each example.

The `snapshot()` function already guards its `readline()` call with
`if (interactive())` in the function body, so non-interactive callers
(including example execution) never trigger the interactive prompt.
