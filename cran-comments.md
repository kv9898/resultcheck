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

The final source archive check, installed-package smoke tests, and release
branch CI are pending.

## Windows remote check

Windows R-devel win-builder validation is pending. This release will not
be submitted to CRAN until its results have been reviewed.
