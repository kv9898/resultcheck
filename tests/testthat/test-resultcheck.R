library(resultcheck)

sandbox <- setup_sandbox("resultcheck-test.R")

test_that("run_tested_script", {
    print(getwd())
    run_in_sandbox("resultcheck-test.R", suppress_messages = F, suppress_warnings = F)
})

cleanup_sandbox()
