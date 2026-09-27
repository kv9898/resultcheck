## Release summary

This patch release fixes default snapshots that fail for common model and
statistical-test objects. Built-in augmentation is omitted where it requires
extra data or saved fit components, only supports particular fits, or always
errors. Invalid broom mappings now use the existing print + str fallback.
No new dependencies are introduced.

The short interval since 0.3.1 is intentional: these bugs prevent ordinary
snapshot calls from completing. Users are advised to review affected baselines.

## R CMD check results

0 errors | 0 warnings | 1 NOTE

The exact submission archive passed R CMD check --as-cran, including PDF
manual generation, on 2026-09-27 using Ubuntu 26.04.1 LTS and R 4.6.1.
The only NOTE reports that HTML manual validation was skipped because the
local system has no HTML Tidy executable. PDF manual generation passed.

## Additional validation

* Local tests: 169 passing assertions and the known sandbox-cleanup warning.
* All package URL checks passed.
* No CRAN reverse dependencies were found.
* Installed-package smoke tests passed for fixest, kmeans, factanal, t-tests,
  correlation tests, explicit augmentation, and the mixed-model fallback.
* GitHub Actions passed for Ubuntu R release and devel, macOS R release,
  Windows R release, and the pkgdown build at source commit e077818:
  https://github.com/kv9898/resultcheck/actions/runs/36296461604

## Windows remote check

The release candidate was uploaded with devtools::check_win_devel(manual = TRUE,
webform = TRUE) on 2026-09-27. The emailed win-builder result is still pending;
we are submitting based on the successful local and GitHub Actions checks.

## Source archive

Source commit: e0778187370bc90438fcabce5ed544fcbf8b7c74
Archive: resultcheck_0.3.2.tar.gz
SHA-256: 695cd8ac1057b350b61fcadbd572434da587d9201fb35051c7c1db84cdd08f76
