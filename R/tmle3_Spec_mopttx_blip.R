#' Defines a TMLE for the Mean Under the Optimal Individualized Rule with Categorical Treatment
#'
#' @importFrom R6 R6Class
#'
#' @export
#
tmle3_Spec_mopttx_blip <- R6Class(
  classname = "tmle3_Spec_mopttx_blip",
  portable = TRUE,
  class = TRUE,
  inherit = tmle3_Spec,
  public = list(
    initialize = function(V, type, b_learner, maximize = TRUE, complex = TRUE, ...) {
      options <- list(V = V, type = type, b_learner = b_learner, maximize = maximize, complex = complex)
      do.call(super$initialize, options)
    },

    vals_from_factor = function(x) {
      sort(unique(x))
    },

    make_updater = function() {
      updater <- tmle3_cv_Update$new()
    },

    make_rules = function(V) {

      # TO DO: Add a variable importance here;
      # right now it naively respects the ordering

      # TO DO: Alternativly re-code this
      V_sub <- list()
      V_sub <- c(list(V))

      for (i in 2:length(V)) {
        V_sub <- c(V_sub, list(V[-1]))
        V <- V[-1]
      }

      return(V_sub)
    },

    make_est_fin = function(fit, max, p.value = 0.05) {

      # Goal: pick the simplest rule, that is significant
      summary_all <- fit$summary

      # Separate static rules:
      lev <- length(fit$tmle_task$npsem$A$variable_type$levels)
      summary_static <- summary_all[((nrow(summary_all) - lev + 1):nrow(summary_all)), ]

      if (max) {
        summary_static <- summary_static[order(summary_static$tmle_est, decreasing = TRUE), ]
      } else {
        summary_static <- summary_static[order(summary_static$tmle_est, decreasing = FALSE), ]
      }

      summary <- summary_all[(1:(nrow(summary_all) - lev)), ]
      summary <- rbind.data.frame(summary, summary_static)

      psi <- summary$tmle_est
      se_psi <- summary$se
      n <- length(fit$estimates[[1]]$IC)

      for (i in 1:length(psi)) {
        if (i + 1 <= length(psi)) {
          # Welch's t-test
          t <- (psi[i] - psi[i + 1]) / (sqrt(se_psi[i]^2 + se_psi[i + 1]^2))
          p <- pt(-abs(t), df = n - 1)

          if (p <= p.value) {
            # res <- summary[i, ]
            res <- i
            break
          } else if ((i + 1) == length(psi)) {
            # all estimates are non-significantly different.
            # names <- summary$param
            # stp <- data.frame(data.frame(do.call("rbind", strsplit(as.character(names), "=", fixed = TRUE)))[, 2])
            # stp <- data.frame(do.call("rbind", strsplit(as.character(stp[, 1]), "}", fixed = TRUE)))[, 1]
            # ind <- min(which(!is.na(suppressWarnings(as.numeric(levels(stp)))[stp]) == TRUE))
            # res <- match(summary[ind, ]$param, fit$summary$param)

            # Return the better static rule:
            # res <- summary_static[1, ]
            res <- length(psi) - lev + 1
          }
        }
      }
      return(res)
    },

    set_B_rule = function(opt) {
      private$B_rule <- opt
    },

    return_rule = function() {
      return(private$B_rule)
    },

    make_params = function(tmle_task, likelihood) {
      V <- private$.options$V
      complex <- private$.options$complex
      max <- private$.options$maximize

      # If complex=TRUE, it will return JUST the learned E[Yd]
      if (complex) {
        # Learn the rule
        opt_rule <- Optimal_Rule$new(tmle_task, likelihood, "split-specific",
          V = V, blip_type = private$.options$type,
          blip_library = private$.options$b_learner, maximize = private$.options$maximize
        )

        opt_rule$fit_blip()
        self$set_B_rule(opt_rule)

        # Define a dynamic Likelihood factor:
        lf_rule <- define_lf(LF_rule, "A", rule_fun = opt_rule$rule)
        intervens <- Param_TSM$new(likelihood, lf_rule)
      } else if (!complex) {
        # TO DO: Order covarates in order of importance
        # Right now naively respects the order

        if (length(V) < 2) {
          stop("This is a simple rule, should be run with complex=TRUE.")
        } else {
          upd <- self$make_updater()
          targ_likelihood <- Targeted_Likelihood$new(likelihood$initial_likelihood, upd)

          V_sub <- self$make_rules(V)

          tsm_rule <- lapply(V_sub, function(v) {
            opt_rule <- Optimal_Rule$new(tmle_task, likelihood, "split-specific",
              V = v, blip_type = private$.options$type,
              blip_library = private$.options$b_learner,
              maximize = private$.options$maximize
            )
            opt_rule$fit_blip()
            self$set_B_rule(opt_rule)

            # Define a dynamic Likelihood factor:
            lf_rule <- define_lf(LF_rule, "A", rule_fun = opt_rule$rule)
            Param_TSM2$new(targ_likelihood, v = v, lf_rule)
          })
        }

        # Define a static intervention for each level of A:
        A_vals <- tmle_task$npsem$A$variable_type$levels

        interventions <- lapply(A_vals, function(A_val) {
          intervention <- define_lf(LF_static, "A", value = A_val)
          tsm <- define_param(Param_TSM, targ_likelihood, intervention)
        })

        intervens <- c(tsm_rule, interventions)
        upd$tmle_params <- intervens

        fit <- fit_tmle3(tmle_task, targ_likelihood, intervens, upd)
        ind <- self$make_est_fin(fit, max = max)
        best_interven <- intervens[[ind]]

        lev <- tmle_task$npsem$A$variable_type$levels
        V_sub_all <- c(V_sub, lev)
        V_sub_all[[self$make_est_fin(fit, max = max)]]

        intervens <- define_param(Param_TSM2, likelihood,
          intervention_list = best_interven$intervention_list,
          v = V_sub_all[[ind]]
        )
      }

      return(intervens)
    }
  ),
  active = list(),
  private = list(
    B_rule = list()
  )
)

#' Mean under the Optimal Individualized Treatment Rule
#'
#' O=(W,A,Y)
#' W=Covariates
#' A=Treatment (binary or categorical)
#' Y=Outcome (binary or bounded continuous)
#'
#' @param V Covariates the rule depends on.
#' @param type One of three psudo-blip versions developed to accommodate categorical treatment. "Blip1"
#' corresponds to chosing a reference category, and defining the blip for all other categories relative to the
#' specified reference. Note that in the case of binary treatment, "blip1" is just the usual blip.
#' "Blip2$ corresponds to defining the blip relative to the average of all categories. Finally,
#' "Blip3" corresponds to defining the blip relative to the weighted average of all categories.
#' @param b_learner Library for blip estimation.
#' @param maximize Specify whether we want to maximize or minimize the mean of the final outcome.
#' @param complex If \code{TRUE}, learn the rule using the specified covariates \code{V}. If
#' \code{FALSE}, check if a less complex rule is better.
#'
#' @export
#'

tmle3_mopttx_blip <- function(V, type = "blip1", b_learner, maximize = TRUE, complex = TRUE) {
  tmle3_Spec_mopttx_blip$new(V = V, type = type, b_learner = b_learner, maximize = maximize, complex = complex)
}
