#' Dynamic Likelihood Factor
#'
#' @importFrom R6 R6Class
#' @importFrom uuid UUIDgenerate
#' @importFrom methods is
#' @family Likelihood objects
#' @keywords data
#'
#' @return \code{LF_base} object
#'
#' @format \code{\link{R6Class}} object.
#'
#' @section Constructor:
#'   \code{define_lf(LF_static, name, type, value, ...)}
#'
#'   \describe{
#'     \item{\code{name}}{character, the name of the factor. Should match a node name in the nodes specified by \code{\link{tmle3_Task}$npsem}
#'     }
#'     \item{\code{type}}{character, either 'density', for conditional density or, 'mean' for conditional mean
#'     }
#'     \item{\code{value}}{the static value
#'     }
#'     \item{\code{...}}{Not currently used.
#'     }
#'     }
#'
#' @section Fields:
#' \describe{
#'     \item{\code{value}}{the static value.}
#'     }

#'
#' @export

LF_rule <- R6Class(
  classname = "LF_rule", portable = TRUE, class = TRUE,
  inherit = LF_base, public = list(
    initialize = function(name,
                              type = "density", rule_fun, ...) {
      super$initialize(name, ..., type = type)
      private$.rule_fun <- rule_fun
    },

    get_mean = function(tmle_task, cv_fold) {
      return(self$rule_fun(tmle_task))
    },

    get_density = function(tmle_task, cv_fold) {
      observed <- tmle_task$get_tmle_node(self$name)
      likelihood <- as.numeric(self$rule_fun(tmle_task) == observed)

      return(likelihood)
    },

    cf_values = function(tmle_task) {
      cf_values <- self$rule_fun(tmle_task)
      return(cf_values)
    }
  ),

  active = list(rule_fun = function() {
    return(private$.rule_fun)
  }),

  private = list(.name = NULL, .rule_fun = NULL, .is_degenerate = TRUE)
)
