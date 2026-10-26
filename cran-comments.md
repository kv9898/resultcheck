## Release summary

This patch release prevents false snapshot mismatches caused by trailing
print padding and corrects script detection when scripts are sourced while
an unrelated editor tab is active. Detection also handles nested sourcing,
missing source references, and the source wrapper used by Positron.
No new dependencies are introduced.

## Local validation

On 2026-10-26 using Ubuntu 26.04.1 LTS and R 4.6.1:

* Full test suite passed with the documented sandbox-cleanup warning.
* Air formatting, documentation regeneration, and whitespace checks passed.
* All package URL checks passed.
* CRAN lists no reverse dependencies (Depends, Imports, LinkingTo, Suggests,
  or Enhances).
* README is maintained as README.md; no generated README needs rebuilding.

## R CMD check results

0 errors | 0 warnings | 1 NOTE

The exact source archive passed R CMD check --as-cran, including remote
incoming checks and PDF manual generation, on the environment above.
The only NOTE reports skipped HTML validation because HTML Tidy is not
installed locally. PDF manual generation passed.

Installed-archive smoke tests passed for separate sourced-script baselines,
repeated comparisons, both source-reference settings, nested sourcing,
sys.source(), trailing print padding, meaningful numeric mismatches, and
linear-model snapshots. The archive was installed into an isolated temporary
library; the user's installed package was not replaced.

GitHub Actions passed for the committed source candidate on Ubuntu R
release and devel, macOS R release, and Windows R release:
https://github.com/kv9898/resultcheck/actions/runs/40306893671

Subsequent validation-record changes affect only this file, which is
excluded from the package archive by .Rbuildignore.

## Windows remote check

The committed 0.3.3 candidate was uploaded with
`devtools::check_win_devel(manual = TRUE)` on 2026-10-26.
Tested source commit: eb5b78f7a2c639b9f7a9544202f32c9918c6354b.
The upload completed successfully; the maintainer result email and check
logs are pending review at the time of submission. The maintainer has
requested submission before those results arrive. Windows R-release and
Linux R-devel CI have passed as recorded above.

## Source archive

Source commit: eb5b78f7a2c639b9f7a9544202f32c9918c6354b
Archive: resultcheck_0.3.3.tar.gz
SHA-256: 0572b78fa1c54ba6fc2563718b10bfce752b8d808a70acbb2e511f60b7f82e69

Submission status and the submitted source commit are recorded separately
in CRAN-SUBMISSION after a successful upload.

## Submission status

The exact checked archive was successfully uploaded to CRAN on 2026-10-26 10:38:42 UTC.
CRAN returned a successful submission response and requested maintainer
email confirmation. Confirmation, acceptance, and publication are pending;
the release PR remains unmerged.
