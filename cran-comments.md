## R CMD check results

0 errors | 0 warnings | 0 notes

Local command (2026-09-15):

```sh
TMPDIR=/var/tmp R --vanilla -q -e 'rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"), error_on = "warning")'
```

The standalone test suite passed 163 assertions with the known sandbox-cleanup
warning; the built source package check completed with Status: OK.

## Test environments

* Local: Ubuntu 26.04.1 LTS, R 4.6.1; release version 0.3.1.
* GitHub Actions: Ubuntu (R release and devel), macOS (R release), and
  Windows (R release), all successful for commit 2df12d5 before the release
  metadata changes:
  https://github.com/kv9898/resultcheck/actions/runs/34873353176
* CI on the final release commit remains to be run before submission.

## Release summary

This patch release fixes session-dependent snapshot serialization that can
produce false differences between interactive R sessions and Quarto renders.

## Key changes since 0.3.0

* Disable fancy quotation marks locally during serialization.
* Set a consistent base R printing limit, configurable through
  `snapshot.max_print` (default: 1000 entries).
* Restore caller options after serialization, including when a method fails.
* Document printing limits and the need to review and regenerate affected
  baselines when upgrading from session-dependent printing.
