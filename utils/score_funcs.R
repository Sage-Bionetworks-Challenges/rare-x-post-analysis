# Compute scores for Task 2 ------------------------------
category_recall <- function(a, b, verbose = FALSE) {
  a.int2 <- tryCatch(
    {
      bedr(input = list(a = a, b = b), method = "intersect -u", params = "-sorted", verbose = verbose)
    },
    error = function(cond) {
      return(data.frame())
    } # return empty df on error
  )
  # fraction of rows in ground truth that overlap at all with peaks in submission
  return(nrow(a.int2) / nrow(a))
}
      