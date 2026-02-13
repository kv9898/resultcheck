library(resultcheck)

model <- lm(mpg ~ wt, data = mtcars)
snapshot(model, "model")
