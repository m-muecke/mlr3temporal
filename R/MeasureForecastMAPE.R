#' @title Mean Absolute Percentage Error Measure
#'
#' @name mlr_measures_forecast.mape
#'
#' @export
#' @include MeasureForecast.R
MeasureForecastMAPE = R6Class("MeasureForecastMAPE",
  inherit = MeasureForecastRegr,
  public = list(
    initialize = function(id = "forecast.mape") {
      super$initialize(id = id, msr("regr.mape"))
    }
  )
)

#' @include aaa.R
measures[["forecast.mape"]] = MeasureForecastMAPE
