#' @title Prediction Object for Forecasting
#'
#' @usage NULL
#' @format [R6::R6Class] object inheriting from [Prediction].
#' @include PredictionForecast.R
#'
#' @description
#' This object wraps the predictions returned by a learner of class LearnerForecast, i.e.
#' the predicted response and standard error.
#'
#' @section Construction:
#' ```
#' p = PredictionForecast$new(task = NULL, row_ids = task$row_ids, truth = task$truth(), response = NULL, se = NULL)
#' ```
#'
#' * `task` :: [TaskRegrForecast]\cr
#'   Task, used to extract defaults for `row_ids` and `truth`.
#'
#' * `row_ids` :: `integer()`\cr
#'   Row ids of the predicted observations, i.e. the row ids of the test set.
#'
#' * `truth` :: `numeric()`\cr
#'     True (observed) outcome.
#'
#' * `response` :: `numeric()`\cr
#'   Object of numeric response values that can be coerced to a data.table.
#'
#' * `se` :: `numeric()`\cr
#'   Object of numeric standard errors that can be coerced to a data.table.
#'
#' @section Fields:
#' All fields from [Prediction], and additionally:
#'
#' * `response` :: `numeric()`\cr
#'   Access to the stored predicted response.
#'
#' * `se` :: `numeric()`\cr
#'   Access to the stored standard error.
#'
#' The field `task_type` is set to `"forecast"`.
#' @section Methods:
#' All Methods from [Prediction], and additionally:
#' * `conf_int(level)`\cr
#'   Access to the stored predicted response.
#'
#' @family Prediction
#' @export
#' @examples
#' task = mlr3::tsk("airpassengers")
#' learner = LearnerRegrForecastAutoArima$new()
#' learner$train(task, 1:30)
#' p = learner$predict(task, 31:50)
PredictionForecast = R6::R6Class("PredictionForecast",
  inherit = Prediction,
  cloneable = FALSE,
  public = list(
    initialize = function(task = NULL, row_ids = task$row_ids, truth = task$truth(), response = NULL, se = NULL, distr = NULL, check = TRUE) {
    
      pdata = list(row_ids = row_ids, truth = truth, response = response, se = se, distr = distr)
      pdata = discard(pdata, is.null)
      class(pdata) = c("PredictionDataForecast", "PredictionData")

      if (check) {
        pdata = check_prediction_data(pdata)
      }

      self$task_type = "forecast"
      self$predict_types = c("response", "se", "distr")[c(!is.null(response), !is.null(se), !is.null(distr))]
      self$man = "mlr3temporal::PredictionForecast"
      self$data = pdata
    },
    help = function() {
      open_help("mlr3temporal::PredictionForecast")
    },
    print = function(...) {
      data = as.data.table(self)
      if (!nrow(data)) {
        catf("%s for 0 observations", format(self))
      } else {
        catf("%s for %i observations:", format(self), nrow(data))
        print(data, nrows = 10L, topn = 3L, class = FALSE, row.names = FALSE, print.keys = FALSE)
      }
    },
    conf_int = function(level = 95) {
      assert_integerish(level, lower = 0, upper = 100)
      lapply(colnames(self$response), function(x) {
        setnames(
          data.table(
            upper = self$response[, ..x] + se_to_ci(se = self$se[, ..x], level),
            lower = self$response[, ..x] - se_to_ci(se = self$se[, ..x], level)
          ),
          c(
            paste0(eval(x), "_upper_", eval(level)),
            paste0(eval(x), "_lower_", eval(level))
          )
        )
      })
    }
  ),
  active = list(
    row_ids = function() self$data$row_ids,
    truth = function() self$data$truth,
    response = function() {
      self$data$response %??% rep(NA_real_, length(self$data$tab$truth$row_id))
    },
    se = function() {
      self$data$se %??% rep(NA_real_, length(self$data$tab$truth$row_id))
    },
    missing = function() {
      miss = logical(nrow(self$data$truth))
      if ("response" %in% self$predict_types) {
        miss[apply(self$response, 1, anyNA)] = TRUE
      }
      if ("se" %in% self$predict_types) {
        miss[apply(self$se, 1, anyNA)] = TRUE
      }

      self$row_ids[miss]
    }
  )
)


#' @export
as.data.table.PredictionForecast = function(x, ...) { # nolint
  # Prefix entries
  tab = map(c("truth", x$predict_types), function(type) {
    xs = copy(x$data[[type]])
    if (length(names(xs)) > 1) {
      setnames(xs, names(xs), paste0(type, ".", names(xs)))
    }
    return(xs)
  })
  tab = do.call('cbind', c(data.table("row_ids" = x$data[["row_ids"]]), tab))
  return(tab)
}
