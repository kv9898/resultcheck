## Resubmission summary

The first 0.3.3 submission was archived by CRAN's automatic pretest on
2026-10-26. All tests passed. Debian checks were OK; Windows R-devel
reported one timing NOTE because the snapshot examples took 11.36 seconds.

This revision reduces the snapshot examples from six calls and two
example projects to three calls in one project. It demonstrates snapshot
creation, a matching comparison, and a custom method. Duplicate sandbox
examples were removed from this help topic; sandbox functions retain their
own examples. Package runtime behavior and dependencies are unchanged.

Previous Windows check:
https://win-builder.r-project.org/incoming_pretest/resultcheck_0.3.3_20261026_114009/Windows/00check.log

Previous Debian check:
https://win-builder.r-project.org/incoming_pretest/resultcheck_0.3.3_20261026_114009/Debian/00check.log

## Validation of the revised candidate

On Ubuntu 26.04.1 LTS with R 4.6.1, 2026-10-26:

* Full local suite passed with the documented sandbox-cleanup warning.
* Documentation regeneration, Air formatting, and whitespace checks passed.
* The revised exact archive passed R CMD check --as-cran with PDF manual
  generation: 0 errors, 0 warnings, 1 NOTE. The NOTE only reports that
  HTML validation was skipped because HTML Tidy is not installed locally.
* snapshot examples took 0.420 seconds in that check, with no timing NOTE.
* The installed-archive example passed in an isolated temporary library,
  taking 0.793 seconds in a fresh R process.
* Instrumentation confirmed 10 configuration reads instead of 20. Separate
  fresh-process timing measured 0.805 seconds versus 1.141 seconds before.

Candidate CI:
https://github.com/kv9898/resultcheck/actions/runs/40313149236
Results are pending; the previous candidate's results are not presented as
validation of this changed archive.

## Revised Windows remote check

Windows R-devel validation was requested for source commit
`a65f45b142501c0183e0b80fb3fb4885df9f0483` on 2026-10-26.
FTP refused the upload before transfer (550); the devtools web-form request
then completed without an HTTP error. Result email and check logs are
pending; Windows example timing has not yet been verified for this revision.

## Revised source archive

Source commit: a65f45b142501c0183e0b80fb3fb4885df9f0483
Archive: resultcheck_0.3.3.tar.gz
SHA-256: 94d264340a1297345245ae901344706f7e9b6c5ac7ecf87d50a91a6f3e449e94

## Submission status

The revised candidate has not been resubmitted. CRAN-SUBMISSION retains the
record of the first upload. Acceptance and publication have not occurred;
the release PR remains unmerged.
