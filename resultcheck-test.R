# Example test script for demonstrating resultcheck workflow
# Run this interactively first to create snapshots, then run the test suite
library(resultcheck)

model <- lm(mpg ~ wt, data = mtcars)
# Explicitly specify script_name to ensure snapshot is saved in the correct location
snapshot(model, "model", script_name = "resultcheck-test")
