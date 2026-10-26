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

Release branch CI is pending:
https://github.com/kv9898/resultcheck/actions/runs/40306893671

## Windows remote check

The committed 0.3.3 candidate was uploaded with
`devtools::check_win_devel(manual = TRUE)` on 2026-10-26.
Tested source commit: eb5b78f7a2c639b9f7a9544202f32c9918c6354b.
The upload completed successfully; the maintainer result email and check
logs are pending review. This release will not be submitted to CRAN until
the results have been reviewed.

## Source archive

Source commit: eb5b78f7a2c639b9f7a9544202f32c9918c6354b
Archive: resultcheck_0.3.3.tar.gz
SHA-256: 0572b78fa1c54ba6fc2563718b10bfce752b8d808a70acbb2e511f60b7f82e69

CRAN submission has not been performed. CRAN-SUBMISSION retains the record
of the previous release until a new submission actually occurs.
