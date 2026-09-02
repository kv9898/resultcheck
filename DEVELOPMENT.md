# Development workflow

This file is the practical checklist for developing and releasing
`resultcheck`. Run commands from the package root.

## Everyday development

Save all edited files, then use this order:

1.  Document the package: `Ctrl+Shift+D`.
2.  Run the tests: `Ctrl+Shift+T`.
3.  Install and restart R: `Ctrl+Shift+B`.
4.  Manually exercise the changed behaviour in the fresh R session.
5.  Check the package: `Ctrl+Shift+E`.

The equivalent R commands are:

``` r

devtools::document()
devtools::test()
devtools::install()
devtools::check()
```

Useful shortcuts:

| Action | Windows/Linux | R equivalent | When to use it |
|----|----|----|----|
| Load all | `Ctrl+Shift+L` | `devtools::load_all()` | Fast iteration without installing |
| Document | `Ctrl+Shift+D` | `devtools::document()` | After changing roxygen comments or exports |
| Test | `Ctrl+Shift+T` | `devtools::test()` | After changing code or tests |
| Install and restart | `Ctrl+Shift+B` | `devtools::install()` | Before manual testing as a package user |
| Check | `Ctrl+Shift+E` | `devtools::check()` | Before a pull request or release |

Edit documentation in the roxygen comments under `R/`, not directly in
generated files under `man/`. Run `Ctrl+Shift+D` afterward and review
changes to both `man/` and `NAMESPACE`.

`Ctrl+Shift+B` installs the package; it does not create the
distributable source archive. To create that archive, use:

``` r

devtools::build()
```

## Before committing or opening a pull request

- Review `git diff` and make sure only intended files changed.
- Run `Ctrl+Shift+D` and check the generated documentation.
- Run `Ctrl+Shift+T` and confirm all tests pass.
- Run `Ctrl+Shift+E` for changes that could affect package checks.
- Confirm `git diff --check` reports no whitespace errors.
- Push the branch and confirm CI passes on all configured platforms.

## Preparing a CRAN release

### 1. Create the release checklist

For a patch release after `0.2.1`, create the `0.2.2` checklist with:

``` r

usethis::use_release_issue("0.2.2")
```

This creates a GitHub issue containing the release tasks. It changes
external GitHub state, so run it only when starting the release process.

### 2. Prepare the release version

During ordinary development after the `0.2.1` release, `DESCRIPTION`
should use a development version:

``` text
Version: 0.2.1.9000
```

Start that development cycle with `usethis::use_dev_version()` if it has
not already been done. Keep unreleased changes under this heading in
`NEWS.md`:

``` markdown
# resultcheck (development version)
```

When the package is ready for a patch release, run:

``` r

usethis::use_version("patch")
```

This changes the package from development version `0.2.1.9000` to
release version `0.2.2`. `use_version()` updates `DESCRIPTION` and
`NEWS.md` and may create a Git commit. Review its proposed actions and
resulting diff.

Before running the final checks, confirm that `DESCRIPTION` contains:

``` text
Version: 0.2.2
```

The source archive submitted to CRAN must contain `0.2.2`, not `0.2.1`,
`0.2.1.9000`, or `0.2.2.9000`.

### 3. Run the local release checks

Use the normal workflow first:

1.  `Ctrl+Shift+D` — document.
2.  `Ctrl+Shift+T` — test.
3.  `Ctrl+Shift+B` — install and manually smoke-test.
4.  `Ctrl+Shift+E` — package check.

Then run the same CRAN-style check used by CI:

``` r

rcmdcheck::rcmdcheck(
  args = c("--no-manual", "--as-cran"),
  error_on = "warning"
)
```

All errors, warnings, and unexpected notes must be resolved or explained
before submission. Also wait for the GitHub Actions checks on macOS,
Windows, Ubuntu release, and R-devel.

### 4. Build and submit

Build the final source package from a clean committed checkout:

``` r

devtools::build()
```

Inspect the generated filename and its included `DESCRIPTION`; both must
show the release version, for example `resultcheck_0.2.2.tar.gz` and
`Version: 0.2.2`.

Follow the remaining tasks in the release issue for submission, CRAN
comments, tagging, and publication. Do not treat a Git tag, a GitHub
Release, and a CRAN release as the same operation; verify each one
separately.

### 5. After CRAN acceptance

Once the release is confirmed on CRAN, the optional usethis helpers are:

``` r

usethis::use_github_release()
usethis::use_dev_version()
```

`use_github_release()` publishes external GitHub state.
`use_dev_version()` starts the next development cycle, for example by
changing `0.2.2` to `0.2.2.9000`; it also updates version-control state,
so review its output.

## Troubleshooting sandbox tests

[`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md)
searches upward for `_resultcheck.yml`, `resultcheck.yml`, an `.Rproj`
file, or `.git`. If temporary sandbox tests unexpectedly copy files from
the wrong location, check whether an ancestor of the temporary directory
contains one of those markers. In particular, a stray `/tmp/.git` can
make `/tmp` look like the project root.

## References

- [RStudio package-development
  shortcuts](https://docs.posit.co/ide/user/ide/reference/shortcuts.html)
- [`usethis::use_release_issue()`](https://usethis.r-lib.org/reference/use_release_issue.html)
- [`usethis::use_version()` and
  `use_dev_version()`](https://usethis.r-lib.org/reference/use_version.html)
