library(resultcheck)

# This test demonstrates the recommended workflow for testing scripts with snapshots:
# 1. Run the script interactively first to create snapshots: source('resultcheck-test.R')
# 2. Then run this test, which uses run_in_sandbox() to verify the script produces
#    the same results as the saved snapshots

test_that("resultcheck-test script runs without errors in sandbox", {
    sandbox <- setup_sandbox("resultcheck-test.R")
    on.exit(cleanup_sandbox(sandbox), add = TRUE)
    
    expect_no_error(
        run_in_sandbox("resultcheck-test.R", suppress_messages = FALSE, suppress_warnings = FALSE)
    )
})
