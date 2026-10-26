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

Documentation, example timing, and package checks are in progress. Results
and the source/archive record below will be updated from this revision's
actual checks. The previous archive's results do not validate this revision.

## Submission status

The revised candidate has not been resubmitted. CRAN-SUBMISSION retains the
record of the first upload. Acceptance and publication have not occurred;
the release PR remains unmerged.
