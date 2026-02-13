library(resultcheck)

sandbox <- setup_sandbox("resultcheck-test.R")

test_that("run_tested_script", {
    expect_no_error(
        run_in_sandbox("resultcheck-test.R", suppress_messages = FALSE, suppress_warnings = FALSE)
    )
})

cleanup_sandbox()
