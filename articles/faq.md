# FAQ

## What is the scope of the package?

`resultcheck` helps you detect when the **results of your analysis
change unexpectedly**.

It does this by snapshotting key outputs (e.g. data, models, tables) and
comparing them when your code is rerun.

For a full example workflow, see the [Get Started
guide](https://kv9898.github.io/resultcheck/articles/resultcheck.md).

In short, `resultcheck` works by snapshotting key results and checking
whether they change when your analysis is rerun.

### Levels of usage

`resultcheck` operates at two main levels:

1.  **Object level**

``` r
snapshot(model, "main_model")
```

This is typically used during **interactive analysis**.

When you are satisfied with a result, you “lock it in” with a snapshot.
On subsequent runs, you will be notified if it changes.

2.  **Script/project level**

``` r
run_in_sandbox("analysis.R", sandbox)
```

This is used for **automated checks**, for example in tests or CI.

It reruns your analysis in a clean environment and verifies that
previously snapshotted results remain unchanged.

This helps detect unintended changes due to:

- code modifications (e.g. refactoring)
- updates from collaborators
- differences in environments (packages, R version, OS)

### Typical workflow

In practice, you might:

- run snapshots interactively while developing your analysis
- run tests (e.g. via [`testthat`](https://testthat.r-lib.org)) before
  committing changes
- optionally use CI (e.g. [GitHub
  Actions](https://kv9898.github.io/resultcheck/articles/renv-github-actions.md)
  ) to run checks automatically

## Can I use resultcheck for exploratory work?

Yes — but with some care.

Academic research and data analysis are often iterative and exploratory,
and new analyses frequently build on earlier results. `resultcheck` can
be useful during this process by helping you ensure that previously
established results remain stable as you continue working.

You can add
[`snapshot()`](https://kv9898.github.io/resultcheck/reference/snapshot.md)
calls gradually as your analysis evolves, and update them when changes
are expected. This allows you to introduce checks incrementally rather
than all at once.

In practice, `resultcheck` works best when used to
`lock in results that you consider stable`, rather than for rapidly
changing intermediate outputs. As your project matures, this makes it
easier to ensure reproducibility and detect unintended changes.

Combined with version control, this also enables you to *refactor and
reorganize your code with confidence*, knowing that you will be alerted
if any key results change unexpectedly.

### Caveat: script and object names

`resultcheck` identifies snapshots based on the **script name** and
**snapshot name**.

This means that:

- renaming a script, or
- changing the name passed to
  [`snapshot()`](https://kv9898.github.io/resultcheck/reference/snapshot.md)

will cause `resultcheck` to treat it as a new snapshot, rather than a
modification of an existing one.

In general, once you have decided to snapshot a result, it is best to
keep:

- script names, and
- snapshot names

stable.

## Is resultcheck a version control system?

No — `resultcheck` does not track code history or file changes.

Instead, it checks whether the **results produced by your analysis**
change when code is rerun.

A helpful way to think about it is:

> Git tracks *what* changed in your code resultcheck tracks *whether
> your results* changed

## How can collaborators track changes in snapshots over time?

`resultcheck` focuses on checking whether results have changed, not on
tracking their history.

Information such as:

- when a snapshot was created  
- who created it  
- which commit it corresponds to

is handled by version control systems such as Git.

In practice, we recommend committing snapshots *alongside* the code
changes that produce them, and writing clear **commit messages** that
explain *why* results changed (e.g. due to code refactoring, data
updates, or dependency changes). This makes it much easier for
collaborators to interpret differences later.

You can inspect snapshot history using Git tools such as:

``` bash
git log tests/_resultcheck_snaps/
git blame tests/_resultcheck_snaps/analysis/model.md
```

These commands show who changed what and when. Many code editors
(e.g. VS Code, Positron) provide a *graphical* interface for this,
allowing you to **trace each line of a snapshot** back to the commit
that introduced it.

This makes it possible to understand changes at a very fine-grained
level, while keeping snapshot files clean and focused on results. In
this workflow, `resultcheck` detects changes in results, and Git
explains them.

## Do I need to save models as `.rds` or `.rda` files to use resultcheck?

No.

You do **not** need to manually save anything to disk.

`resultcheck` snapshots objects directly as `.md` files, for example:

``` r
model <- lm(mpg ~ wt, data = mtcars)
snapshot(model, "main_model")
```

This will create a snapshot file at:
`tests/_resultcheck_snaps/[your_script_name]/main_model.md`.

## How does resultcheck differ from manually comparing the `.rds` or `.rda` files?

`.rds` and `.rda` files are binary formats, which can be large and
difficult to compare directly.

In contrast, resultcheck stores snapshots as `.md` files, which are:

- human-readable
- easy to compare (e.g. with Git diffs)
- version control-friendly

We recommend committing these snapshot files to **version control**.
This allows you to:

- see how results change across revisions
- collaborate more effectively
- automatically detect unintended changes via tests or CI

## Does resultcheck track changes over time?

No — it compares against the **current snapshot**.

It does not maintain a full history like version control.

If you want history, use Git — `resultcheck` complements it.

## What about large projects — is the sandbox expensive?

[`setup_sandbox()`](https://kv9898.github.io/resultcheck/reference/setup_sandbox.md)
copies files into a temporary directory.

For very large projects, this can be expensive in time and disk space.

Current recommendations:

- include only necessary files
- avoid copying large unused directories

Future versions may include:

- size warnings
- more selective copying

## Is find_root() the same as here::here()?

Not exactly.

[`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md)
is an internal helper used by resultcheck to locate the project root. It
is primarily used to identify which files (e.g. data, saved objects)
should be copied into the sandbox when running analyses in a clean
environment.

Unlike `here::here()`,
[`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md)
will **error if no project root is found**, rather than guessing a path.
This is intentional, to avoid silently writing or reading files from the
wrong location.

In most cases, you should **not** need to call
[`find_root()`](https://kv9898.github.io/resultcheck/reference/find_root.md)
directly.

For constructing file paths in your own analysis code, we recommend
using `here::here()` (or equivalent tools), as it is more flexible and
designed for everyday use.

## Can I see exactly what changed in a model?

Currently, `resultcheck` reports differences as text diffs.

For example:

``` r
Warning: 
Snapshot differences found for: model
File: E:/OneDrive/Desktop/ark-test/tests/_resultcheck_snaps/resultcheck-test/model.md

Differences:
old[2:8] vs new[2:8]
  ""
  "## List Structure"
  "List of 12"
- " $ coefficients : Named num [1:2] 40.03 -5.34"
+ " $ coefficients : Named num [1:2] 37.29 -5.34"
  "  ..- attr(*, \"names\")= chr [1:2] \"(Intercept)\" \"wt\""
  " $ residuals    : Named num [1:32] -2.28 -0.92 -2.09 1.3 -0.2 ..."
  "  ..- attr(*, \"names\")= chr [1:32] \"Mazda RX4\" \"Mazda RX4 Wag\" \"Datsun 710\" \"Hornet 4 Drive\" ..."

Update snapshot? (y/n): 
```

More structured comparisons are a possible future extension.
