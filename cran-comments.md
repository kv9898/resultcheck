## Release summary

This patch release fixes default snapshots that fail for common model and
statistical-test objects. Built-in augmentation is omitted where it requires
extra data or saved fit components, only supports particular fits, or always
errors. Invalid broom mappings now use the existing print + str fallback.
No new dependencies are introduced.

The short interval since 0.3.1 is intentional: these bugs prevent ordinary
snapshot calls from completing. Users are advised to review affected baselines.

## Validation

Release-candidate local checks and GitHub Actions checks are in progress.
Final results will be recorded here before submission.

Windows R-devel win-builder testing will be requested separately. Its results
are not being treated as a prerequisite for this submission; local and GitHub
Actions checks must pass before submission.
