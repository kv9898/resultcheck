# Read input data
data <- read.csv("data/income.csv")

# Fit a linear model
model <- lm(income ~ age + education, data = data)

# Snapshot the model to detect unexpected result changes across code revisions.
# In interactive use: warns and prompts to update when differences are found.
# Inside run_in_sandbox(): errors if the snapshot is missing or doesn't match.
resultcheck::snapshot(model, "income_model")

# Write model summary to an output file
dir.create("output", showWarnings = FALSE)
write.csv(
  as.data.frame(coef(summary(model))),
  "output/model_summary.csv"
)
