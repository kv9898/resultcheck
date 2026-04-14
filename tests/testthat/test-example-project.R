test_that("example project helper creates consistent runnable files", {
  skip_if_not_installed("withr")

  with_example({
    expect_true(file.exists("_resultcheck.yml"))
    expect_true(file.exists("analysis.R"))
    expect_true(file.exists(file.path("tests", "_resultcheck_snaps", "analysis", "model.md")))
    expect_true(file.exists(file.path("tests", "_resultcheck_snaps", "analysis", "model_mismatch.md")))
    expect_true(file.exists(file.path("tests", "testthat", "test-analysis.R")))

    sandbox <- setup_sandbox()
    on.exit(cleanup_sandbox(sandbox), add = TRUE)
    expect_true(run_in_sandbox("analysis.R", sandbox))
  })
})


test_that("example project helper supports mismatch demos", {
  skip_if_not_installed("withr")

  with_example({
    sandbox <- setup_sandbox()
    on.exit(cleanup_sandbox(sandbox), add = TRUE)

    expect_error(
      run_in_sandbox("analysis.R", sandbox),
      "Snapshot differences found"
    )
  }, mismatch = TRUE)
})
