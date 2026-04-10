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

The `snapshot()` function is intentionally a file-writing function: its core
purpose is to persist human-readable `.md` snapshots in
`_resultcheck_snapshots/` at the project root so they can be committed to
version control and detected by `find_root()` on subsequent runs.  Writing to
the user's project directory is therefore not incidental but a fundamental part
of the package's design, and this is now stated explicitly in the
`snapshot()` documentation.

The `\donttest{}` wrapper ensures examples are skipped during automated `R CMD
check` runs.  The interactive overwrite prompt inside `snapshot()` is already
guarded by `if (interactive())` in the function body, so non-interactive
callers (including example runners) never trigger it.

The sandbox functions (`setup_sandbox()`, `run_in_sandbox()`,
`cleanup_sandbox()`) create their working directories inside `tempdir()` via
`tempfile()` and do not write to the user's home directory.
