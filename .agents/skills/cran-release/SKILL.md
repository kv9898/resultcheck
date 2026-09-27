---
name: cran-release
description: Prepare, validate, submit, and complete CRAN releases for R packages, including release branches, submission records, and post-acceptance cleanup. Use for CRAN release preparation, submission, or resuming an existing release; not ordinary package development.
---

# CRAN release

Carry out the requested release stage using the project's conventions. Preserve existing authorization: a request to complete a release covers its necessary steps, but preparation-only work does not authorize submission. Ask only for consequential missing decisions, inaccessible confirmation steps, or genuinely required permissions. Do not turn this skill into an additional approval gate.

## Establish release state

- Read `AGENTS.md`, `DEVELOPMENT.md` or other release instructions, `DESCRIPTION`, `NEWS.md`, `cran-comments.md`, and `CRAN-SUBMISSION` when present. Inspect Git status, remotes, tags, open release issues/PRs, and their checks. Preserve unrelated changes; reuse an existing release branch or checklist where appropriate.
- Check the live CRAN package page, check results, and current [repository policy](https://cran.r-project.org/web/packages/policies.html). Verify the published version, publication date, reverse dependencies, and any known pending submission. Derive the next version from that evidence and the change scope; never hardcode a version or maintainer identity.
- Recognize separate states: prepared archive, uploaded submission, maintainer confirmation, CRAN acceptance, CRAN publication, Git tag, and GitHub Release. Require evidence for each. An upload receipt or confirmation email is not acceptance.
- If the release interval is unusually short, explain the concrete bug-fix justification in the submission comments; discuss timing only if the user's intent leaves it unresolved.

## Prepare and validate

- Create or reuse the release branch, checklist, and PR according to repository practice. Set the release version without a development suffix; finalize NEWS and refresh CRAN comments with actual results, dates, environments, and CI links. Do not copy old check counts or success claims.
- Run the project's formatter/checker, documentation generator, tests, and installed-package smoke tests for changed behavior. Review generated changes. Wait for the relevant platform CI jobs, including R-devel when configured.
- Check affected reverse dependencies, recording failures and whether they also occur with the published version. Resolve release-caused failures before submission; follow CRAN policy if downstream coordination is needed.
- Build a source archive from a clean committed checkout with current R release/patched. Verify its filename and embedded DESCRIPTION version. Record the source commit and archive checksum so submission uses the checked artifact.
- Run `R CMD check --as-cran` on that exact archive, including manual generation. Use R-devel where available; otherwise document the environment and use project CI or appropriate builders for additional coverage. Fix errors and warnings; explain any remaining legitimate notes. If source changes, rebuild and recheck before submission.
- Install the candidate into an isolated temporary library for smoke tests unless the user requests a normal installation. Do not replace or restart the user's live R session as an incidental release step.
- Apply environment workarounds only when demonstrated. For resultcheck's documented ancestor-root issue, use a writable `TMPDIR=/var/tmp` when a stray `/tmp/.git` makes sandbox tests resolve the wrong root. Do not delete the marker or change package code to hide the environment issue.

## Submit or resume

- For preparation-only requests, stop with the archive path, checksum, source commit, PR, validation results, and remaining steps. Do not upload.
- Within an authorized submission, use CRAN's official [submission form](https://cran.r-project.org/submit.html), or an established project submission tool that uses it, to upload the exact checked source archive. Supply accurate maintainer information and concise release comments.
- Verify the submission receipt before recording success. Update `CRAN-SUBMISSION` with version, actual submission time, and the archive's source commit; the later bookkeeping commit is not the submitted source commit. Commit and push the record using project conventions.
- The maintainer must complete CRAN's email confirmation. If that confirmation or feedback is unavailable through authorized tools, ask the user to complete it or provide the relevant status. Do not claim access to an inbox or unattended monitoring you do not have.
- When resuming, establish the current submission status before uploading anything. Never resubmit while the earlier upload is pending. After CRAN feedback, address it, explain the response, and rebuild/recheck changed artifacts before any authorized resubmission.
- If acceptance is still pending, report the exact state and next step, preserving the release branch and PR. Do not report the overall release complete.

## Complete after acceptance

- Follow the repository's required merge, cleanup, and tag order. In resultcheck, `DEVELOPMENT.md` requires submitting from the open release PR, waiting for confirmed CRAN acceptance, squash-merging into main, switching to and syncing main, deleting the release branch locally/remotely, and tagging the squash-merge commit with the release version. This is a project convention, not a universal CRAN requirement.
- Verify the accepted source corresponds to the release changes before merging/tagging; resolve divergence rather than tagging unrelated code. Preserve an existing tag instead of moving it silently.
- Verify the merged PR, clean synchronized main, deleted release branches, remote tag target, and CRAN publication separately. Close the release checklist only when its required steps are complete. If acceptance precedes public availability, report publication as pending.
- A GitHub Release and the next development-version bump are separate optional actions. Perform them only when included in the user's scope or established project workflow.
- Finish with version, CRAN/PR/tag links, final commit, validation summary, and any precisely identified pending external step.
