library(resultcheck)

# This test demonstrates the recommended workflow for testing scripts with snapshots.
# The test creates the snapshot first, then runs the script in a sandbox to verify
# it produces the same results.

test_that("resultcheck-test script runs without errors in sandbox", {
    # Step 1: Create the snapshot first (simulating interactive workflow)
    model <- lm(mpg ~ wt, data = mtcars)
    snapshot(model, "model", script_name = "resultcheck-test")
    
    # Step 2: Run the script in sandbox (should match the snapshot)
    sandbox <- setup_sandbox("resultcheck-test.R")
    on.exit(cleanup_sandbox(sandbox), add = TRUE)
    
    expect_no_error(
        run_in_sandbox("resultcheck-test.R", suppress_messages = FALSE, suppress_warnings = FALSE)
    )
})
