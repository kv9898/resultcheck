# Example test script for demonstrating resultcheck workflow
# Run this interactively first to create snapshots, then run the test suite
library(resultcheck)

# Explicitly specify script_name to ensure snapshot is saved in the correct location
result <- data.frame(mean_mpg = mean(mtcars$mpg), n = nrow(mtcars))
snapshot(result, "result", script_name = "resultcheck-test")
