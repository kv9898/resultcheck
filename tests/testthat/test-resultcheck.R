library(resultcheck)

# This test demonstrates the recommended workflow for testing scripts with snapshots:
# 1. Run the script interactively first to create snapshots: source('resultcheck-test.R')
# 2. Then run this test, which uses run_in_sandbox() to verify the script produces
#    the same results as the saved snapshots

sandbox <- setup_sandbox("resultcheck-test.R")

test_that("run_tested_script", {
    expect_no_error(
        run_in_sandbox("resultcheck-test.R", suppress_messages = FALSE, suppress_warnings = FALSE)
    )
})

cleanup_sandbox()
