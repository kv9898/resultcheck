#' @importFrom utils getSrcref str
#' @importFrom grDevices dev.off pdf
NULL

#' Reset sandbox state (internal)
#' @keywords internal
.reset_last_sandbox <- function() {
  .resultcheck_env$last_sandbox <- NULL
}