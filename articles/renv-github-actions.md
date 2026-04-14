# Automated Testing with GitHub Actions

This vignette shows how to combine `resultcheck`, `testthat`, `renv`,
and a GitHub Actions workflow into a fully automated reproducibility
pipeline. The goal is to make every push to your repository trigger a
test run that fails loudly whenever any analysis result drifts from its
committed snapshot — across all three major operating systems.

For a real-world example of this pattern in action, see the [IMF
replication repository](https://github.com/IMFPaper/IMF).

------------------------------------------------------------------------

## Why each piece matters

| Tool | Role |
|----|----|
| `resultcheck` | Captures named snapshots of R objects; errors in CI when a snapshot changes |
| `testthat` | Test harness that runs the snapshots and reports failures |
| `renv` | Locks every package to an exact version so the environment is reproducible |
| GitHub Actions | Runs the test suite automatically on push/PR across Windows, macOS, and Linux |

Without `renv`, a routine package update could silently change a
coefficient or table. Without snapshots, tests would not catch numerical
drift. Without multi-OS CI, platform-specific floating-point differences
would go unnoticed.

------------------------------------------------------------------------

## Step 1 — Project layout

A minimal project that uses this workflow looks like:

    myproject/
    ├── .Rprofile                   # auto-activates renv
    ├── renv.lock                   # locked package versions (committed)
    ├── renv/                       # renv internals (mostly gitignored)
    ├── _resultcheck.yml             # marks the project root
    ├── data/
    │   └── panel_data.rds
    ├── code/
    │   └── analysis.R              # your analysis script
    ├── tests/_resultcheck_snaps/     # committed snapshot files
    │   └── analysis/
    │       └── main_model.md
    └── tests/
        └── testthat/
            └── test-analysis.R

The `_resultcheck.yml` file at the root can be empty — its presence is
enough for
[`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md)
to locate the project:

``` yaml
# _resultcheck.yml
```

------------------------------------------------------------------------

## Step 2 — Initialise renv

Inside R, with your project open:

``` r

install.packages("renv")
renv::init()
```

Install the packages your project needs, then snapshot the environment:

``` r

renv::install(c("resultcheck", "testthat"))
# ... install any other packages your analysis uses ...
renv::snapshot()
```

Commit both `.Rprofile` and `renv.lock`. The `renv/` folder should be
partially ignored according to renv’s own `.gitignore` (created
automatically by
[`renv::init()`](https://rstudio.github.io/renv/reference/init.html)).

------------------------------------------------------------------------

## Step 3 — Add snapshots to your analysis script

Call
[`resultcheck::snapshot()`](https://kv9898.github.io/resultcheck/reference/snapshot.md)
on every object whose value matters for reproducibility. The first time
you run the script interactively the snapshot is saved; on all
subsequent runs it is compared against the saved version.

``` r

# code/analysis.R
data  <- readRDS("data/panel_data.rds")
model <- lm(y ~ x1 + x2, data = data)

resultcheck::snapshot(model,  "main_model")
resultcheck::snapshot(data,   "panel_data")

# ... continue writing outputs ...
```

Run the script interactively once to generate the `.md` snapshot files,
review them, then commit them to version control.

------------------------------------------------------------------------

## Step 4 — Write a testthat test

``` r

# tests/testthat/test-analysis.R
library(testthat)
library(resultcheck)

test_that("analysis produces stable results", {
  sandbox <- setup_sandbox("data")
  on.exit(cleanup_sandbox(sandbox), add = TRUE)

  # snapshot() inside run_in_sandbox() errors on any mismatch
  expect_true(run_in_sandbox("code/analysis.R", sandbox))
})
```

Run locally to confirm everything passes before pushing:

``` r

testthat::test_dir("tests/testthat")
```

For package examples and quick demos, you can avoid writing into your
current project by wrapping code in `resultcheck::with_example({...})`,
which creates a temporary project in
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) and cleans it up
automatically.

------------------------------------------------------------------------

## Step 5 — GitHub Actions workflow

Create `.github/workflows/run-tests.yml`. The key ingredients are:

- **Matrix strategy** — runs on Windows, macOS, and Ubuntu so
  platform-specific numerical differences are caught early.
- **OS-specific system libraries** — packages such as `ragg`, `xml2`, or
  `curl` need native libraries on Linux and macOS that are not required
  on Windows.
- **renv cache** — `r-lib/actions/setup-renv@v2` restores the `renv`
  cache between runs, avoiding re-installing hundreds of packages on
  every push.

``` yaml
name: R Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test:
    runs-on: ${{ matrix.config.os }}
    name: ${{ matrix.config.os }}

    strategy:
      fail-fast: false
      matrix:
        config:
          - {os: windows-latest}
          - {os: ubuntu-latest}
          - {os: macos-latest}

    env:
      GITHUB_PAT: ${{ secrets.GITHUB_TOKEN }}
      R_KEEP_PKG_SOURCE: yes

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Setup R
        uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      # ── Linux system libraries ──────────────────────────────────────────
      - name: Install system dependencies (Linux)
        if: runner.os == 'Linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y \
            libcurl4-openssl-dev \
            libssl-dev \
            libxml2-dev \
            libfontconfig1-dev \
            libharfbuzz-dev \
            libfribidi-dev \
            libfreetype6-dev \
            libpng-dev \
            libtiff5-dev \
            libjpeg-dev

      # ── macOS system libraries ───────────────────────────────────────────
      - name: Install system dependencies (macOS)
        if: runner.os == 'macOS'
        run: |
          set -euxo pipefail
          brew update
          brew install pkg-config libpng cairo freetype harfbuzz fribidi

          BREW_PREFIX="$(brew --prefix)"
          echo "SDKROOT=$(xcrun --sdk macosx --show-sdk-path)" >> $GITHUB_ENV
          echo "PATH=${BREW_PREFIX}/bin:${PATH}"               >> $GITHUB_ENV
          echo "PKG_CONFIG_PATH=${BREW_PREFIX}/lib/pkgconfig:$(brew --prefix libpng)/lib/pkgconfig" >> $GITHUB_ENV

          mkdir -p ~/.R
          PNG_CFLAGS="$(pkg-config --cflags libpng)"
          PNG_LIBS="$(pkg-config --libs   libpng)"
          {
            echo "CPPFLAGS += -I${BREW_PREFIX}/include"
            echo "LDFLAGS  += -L${BREW_PREFIX}/lib -Wl,-rpath,${BREW_PREFIX}/lib"
            echo "PKG_CPPFLAGS += ${PNG_CFLAGS}"
            echo "PKG_LIBS     += ${PNG_LIBS}"
          } >> ~/.R/Makevars

      # ── Restore renv cache (fast!) ───────────────────────────────────────
      - name: Restore renv packages
        uses: r-lib/actions/setup-renv@v2
        with:
          cache-version: 2

      # ── Run tests ────────────────────────────────────────────────────────
      - name: Run tests
        run: Rscript -e "testthat::test_dir('tests/testthat')"

      - name: Upload test artefacts on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: test-results-${{ matrix.config.os }}
          path: tests/testthat/*.Rout*
```

### How `setup-renv` caching works

`r-lib/actions/setup-renv@v2` reads your `renv.lock` file, computes a
cache key from its hash, and restores a previously saved cache of
installed packages before calling
[`renv::restore()`](https://rstudio.github.io/renv/reference/restore.html).
When the lock file has not changed, all packages are served from the
cache and
[`renv::restore()`](https://rstudio.github.io/renv/reference/restore.html)
completes in seconds rather than minutes.

Increment `cache-version` (e.g. from `2` to `3`) whenever you want to
force a full re-install — for example after an OS upgrade or when
debugging a strange linking error.

------------------------------------------------------------------------

## Step 6 — Snapshot lifecycle on CI

    Developer                         CI runner
    ─────────                         ─────────
    1. Edit analysis.R
    2. Run interactively → snapshots
       generated / updated
    3. Review diffs, accept changes
    4. git add tests/_resultcheck_snaps/
       git commit && git push
                                      5. Workflow triggered
                                      6. renv::restore() (from cache)
                                      7. testthat::test_dir()
                                         └─ run_in_sandbox("code/analysis.R")
                                            └─ snapshot() in *testing mode*
                                               ✓ matches committed file → pass
                                               ✗ differs             → FAIL

CI never updates snapshots; it only enforces them. To accept a
legitimate result change, always re-run the script interactively,
confirm the diff, and commit the updated `.md` files.

------------------------------------------------------------------------

## Handling platform differences

When the same computation yields slightly different floating-point
values on different operating systems, use the mechanisms described in
[`vignette("snapshot-tolerance")`](https://kv9898.github.io/resultcheck/articles/snapshot-tolerance.md):

- **`[ignored]` markers** — replace a volatile line in the snapshot file
  with the literal text `[ignored]`. That line position is skipped on
  every platform.
- **`snapshot.precision`** — add a `precision` key to `_resultcheck.yml`
  to round all floating-point numbers before comparison:

``` yaml
# _resultcheck.yml
snapshot:
  precision: 10
```

Either option lets CI pass on all platforms without losing the safety
net on the lines that do matter.

------------------------------------------------------------------------

## Tips

- **Commit `renv.lock` but not `renv/library/`.** The library is rebuilt
  from the lock file on each runner; only the lock file needs to be in
  version control.
- **Keep snapshots human-readable.** The `.md` files produced by
  [`snapshot()`](https://kv9898.github.io/resultcheck/reference/snapshot.md)
  are plain text and diff well in pull requests — reviewers can see at a
  glance whether a coefficient changed.
- **Pin your R version** in the workflow matrix
  (e.g. `r-version: '4.4.2'`) if minor R releases have ever changed your
  numerical results.
- **`fail-fast: false`** lets all three OS jobs run to completion even
  when one fails, giving you a full picture of where the discrepancy
  occurs.
- **`workflow_dispatch`** allows you to trigger the workflow manually
  from the GitHub Actions UI — useful for debugging without having to
  push a commit.
