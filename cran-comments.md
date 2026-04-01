# CRAN submission comments — resultcheck 0.1.0

## Test environments

* Local: Ubuntu 22.04, R 4.5.3
* GitHub Actions CI: ubuntu-latest, R release

## R CMD CHECK results

0 ERRORs | 0 WARNINGs | 0 NOTEs

## Notes for CRAN reviewers

* This is the first CRAN submission.
* The package has no compiled code.
* All examples are wrapped in `\dontrun{}` because they require a live project
  directory (a `.git` or `.Rproj` marker) to locate the project root.
* `inst/extdata/` contains a small example dataset (`data/income.csv`) and a
  corresponding analysis script (`analysis.R`) used by the package tests.
