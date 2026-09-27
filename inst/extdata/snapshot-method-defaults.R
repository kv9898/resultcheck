# Built-in class-based snapshot method defaults.
# Define `method_by_class` as a named list where each value is a method
# expression string (for example "summary") or a method spec.
#
# These defaults provide sensible snapshotting methods for common R classes:
# - "print"  : uses the object's print method
# - "str"    : uses str() to show structure
# - "summary": uses summary() (best for statistical models like lm, glm)
# - etc. (any function accessible via name or pkg::name syntax)
method_by_class <- list(
  # Linear models - broom::tidy gives useful coefficients table
  lm = c("broom::tidy", "broom::glance", "broom::augment"),
  glm = c("broom::tidy", "broom::glance", "broom::augment"),
  aov = c("broom::tidy", "broom::glance"),
  manova = "broom::tidy",

  # Extended linear models (broom supports tidy + glance for all)
  lm.beta = "broom::tidy",
  lmodel2 = c("broom::tidy", "broom::glance"),
  biglm = c("broom::tidy", "broom::glance"),
  # Augmentation requires explicit data or a fit with saved fitted values.
  speedlm = c("broom::tidy", "broom::glance"),

  # Robust linear models
  rlm = c("broom::tidy", "broom::glance", "broom::augment"),
  lmrob = c("broom::tidy", "broom::glance", "broom::augment"),
  lmRob = c("broom::tidy", "broom::glance", "broom::augment"),
  glmrob = "broom::tidy",
  # The broom augmentation method is deprecated and always errors.
  glmRob = c("broom::tidy", "broom::glance"),

  # Regularized/glmnet models
  glmnet = c("broom::tidy", "broom::glance"),
  cv.glmnet = c("broom::tidy", "broom::glance"),

  # Nonlinear models
  nls = c("broom::tidy", "broom::glance", "broom::augment"),
  nlrq = c("broom::tidy", "broom::glance", "broom::augment"),

  # Mixed models (lme/merMod and subclasses) use print + str unless the
  # user configures methods from a provider such as broom.mixed.

  # GAM models
  gam = c("broom::tidy", "broom::glance", "broom::augment"),
  Gam = c("broom::tidy", "broom::glance"),

  # Survival models
  coxph = c("broom::tidy", "broom::glance", "broom::augment"),
  survreg = c("broom::tidy", "broom::glance", "broom::augment"),
  aareg = c("broom::tidy", "broom::glance"),
  cch = c("broom::tidy", "broom::glance"),
  crr = c("broom::tidy", "broom::glance"),
  survfit = c("broom::tidy", "broom::glance"),
  survdiff = c("broom::tidy", "broom::glance"),
  survexp = c("broom::tidy", "broom::glance"),
  muhaz = c("broom::tidy", "broom::glance"),
  pyears = c("broom::tidy", "broom::glance"),

  # Time series / ARIMA
  Arima = c("broom::tidy", "broom::glance"),
  acf = "broom::tidy",
  spec = "broom::tidy",
  ts = "broom::tidy",
  zoo = "broom::tidy",

  # Bayesian classes stanfit and bamlss also have no built-in broom mapping.

  # Panel data models
  plm = c("broom::tidy", "broom::glance", "broom::augment"),

  # Count / GLM extensions
  negbin = c("broom::tidy", "broom::glance"),
  # The broom augmentation method is an error-only stub.
  speedglm = c("broom::tidy", "broom::glance"),

  # GEE models
  geeglm = c("broom::tidy", "broom::glance"),

  # Ordinal models
  polr = c("broom::tidy", "broom::glance", "broom::augment"),
  clm = c("broom::tidy", "broom::glance", "broom::augment"),
  clmm = c("broom::tidy", "broom::glance"),
  svyolr = c("broom::tidy", "broom::glance"),

  # Multinomial models
  multinom = c("broom::tidy", "broom::glance"),
  mlogit = c("broom::tidy", "broom::glance", "broom::augment"),

  # Beta regression
  betareg = c("broom::tidy", "broom::glance", "broom::augment"),

  # Cure regression
  crr = c("broom::tidy", "broom::glance"),

  # Cluster analysis
  # Requires explicit data for augmentation.
  kmeans = c("broom::tidy", "broom::glance"),
  Mclust = c("broom::tidy", "broom::glance", "broom::augment"),
  pam = c("broom::tidy", "broom::glance", "broom::augment"),

  # PCA / dimension reduction
  prcomp = c("broom::tidy", "broom::augment"),
  # Augmentation requires scores, which are not saved by default.
  factanal = c("broom::tidy", "broom::glance"),

  # DEA / stochastic frontier
  felm = c("broom::tidy", "broom::glance", "broom::augment"),
  ridgelm = c("broom::tidy", "broom::glance"),

  # Quantile regression
  rq = c("broom::tidy", "broom::glance", "broom::augment"),
  rqs = c("broom::tidy", "broom::glance", "broom::augment"),

  # GMM
  gmm = c("broom::tidy", "broom::glance"),

  # Instrumental variables
  ivreg = c("broom::tidy", "broom::glance", "broom::augment"),

  # Meta-analysis
  rma = c("broom::tidy", "broom::glance", "broom::augment"),

  # Network models
  ergm = c("broom::tidy", "broom::glance"),
  btergm = "broom::tidy",
  sarlm = c("broom::tidy", "broom::glance", "broom::augment"),
  Sarlm = c("broom::tidy", "broom::glance", "broom::augment"),

  # Marginal effects
  mfx = c("broom::tidy", "broom::glance", "broom::augment"),
  betamfx = c("broom::tidy", "broom::glance", "broom::augment"),
  logitmfx = c("broom::tidy", "broom::glance", "broom::augment"),
  probitmfx = c("broom::tidy", "broom::glance", "broom::augment"),
  negbinmfx = c("broom::tidy", "broom::glance", "broom::augment"),
  poissonmfx = c("broom::tidy", "broom::glance", "broom::augment"),
  margins = c("broom::tidy", "broom::glance", "broom::augment"),

  # Fixest models
  # Requires explicit data for augmentation.
  fixest = c("broom::tidy", "broom::glance"),

  # Survey models
  svyglm = c("broom::tidy", "broom::glance"),

  # Latent class
  poLCA = c("broom::tidy", "broom::glance", "broom::augment"),

  # Joint models
  mjoint = c("broom::tidy", "broom::glance", "broom::augment"),

  # DRM / DRC
  # Requires explicit data or newdata for augmentation.
  drc = c("broom::tidy", "broom::glance"),

  # GARCH
  garch = c("broom::tidy", "broom::glance"),

  # ANOVA extensions
  anova = c("broom::tidy", "broom::glance"),
  aovlist = "broom::tidy",

  # Coefficient tests
  coeftest = c("broom::tidy", "broom::glance"),

  # Tests and diagnostics
  # Augmentation only supports chi-squared tests, not general htest objects.
  htest = c("broom::tidy", "broom::glance"),
  durbinWatsonTest = c("broom::tidy", "broom::glance"),

  # Confidence intervals
  confint.glht = "broom::tidy",
  glht = "broom::tidy",
  summary.glht = "broom::tidy",

  # Bootstrapping
  boot = "broom::tidy",

  # Statistical tests
  pairwise.htest = "broom::tidy",
  leveneTest = "broom::tidy",
  TukeyHSD = "broom::tidy",

  # Table/matrix summaries
  table = "broom::tidy",
  ftable = "broom::tidy",
  confusionMatrix = "broom::tidy",

  # Variance models
  varest = c("broom::tidy", "broom::glance"),
  lavaan = c("broom::tidy", "broom::glance"),
  ref.grid = "broom::tidy",
  emmGrid = "broom::tidy",
  summary_emm = "broom::tidy",
  lsmobj = "broom::tidy",

  # Binomial design
  binDesign = c("broom::tidy", "broom::glance"),
  binWidth = "broom::tidy",
  power.htest = "broom::tidy"
)
