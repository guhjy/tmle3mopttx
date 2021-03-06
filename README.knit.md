---
output: rmarkdown::github_document
bibliography: README-refs.bib
---

<!-- README.md is generated from README.Rmd. Please edit that file -->



# R/`tmle3mopttx`

[![Project Status: WIP - Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)

> Targeted Learning and Variable Importance with Optimal Individualized Categorical Treatment

__Authors:__ [Ivana Malenica](https://github.com/podTockom), [Jeremy R. Coyle](https://github.com/jeremyrcoyle) and [Mark J. van der Laan](https://vanderlaan-lab.org/)

## Description

Suppose one wishes to maximize (or minimize) the population mean of an outcome using a categorical point treatment, where for each individual one has access to measured baseline covariates. We consider estimation of the mean outcome under the optimal rule, where the candidate rules are restricted to depend only on user-supplied subset of the baseline covariates. The estimation problem is addressed in a statistical model for the data distribution that is nonparametric, and at most places restrictions on the probability of a patient receiving treatment given covariates. In addition, suppose one wishes to assess the importance of each observed covariate, in terms of maximizing (or minimizing) the population mean of an outcome under an optimal individualized treatment regime. 

`tmle3mopttx` is an adapter/extension R package in the `tlverse` ecosystem, that addresses the above mentioned problems. The goal of this work is to build upon the `tlverse` framework and the estimation methodology implemented for a single mean counterfactual outcome in order to introduce an end-to-end methodology for variable importance analyses. It relies on the modern implementation of the Super Learner algorithm, [sl3](https://github.com/tlverse/sl3), and [tmle3](https://github.com/tlverse/tmle3) for the targeting step. 

In order to avoid nested cross-validation, `tmle3mopttx` relies on split-specific estimates of $\mathbb{E}(Y|A,W)$ and $P(A|W)$ in order to estimate the rule, as described by Coyle et al. In addition, the targeted maximum likelihood estimates of the mean performance under the estimated rule are obtained using CV-TMLE. The implementation supports categorical treatments, providing three different versions for the rule estimation, as well as Q-learning. 

For additional background on Targeted Learning and previous work on optimal individualized treatment regimes, please consider consulting @vdl2007super, @cvtmle2010, @vdl2011targeted, @vanderLaanLuedtke15, @luedtke2016super, @jeremythesis and @vdl2018targeted.

---

## Installation

You can install the most recent _stable release_ from GitHub via [`devtools`](https://www.rstudio.com/products/rpackages/devtools/) with:
                                                                                              

```r
devtools::install_github("tlverse/tmle3mopttx")
```

---

## Issues

If you encounter any bugs or have any specific feature requests, please [file an
issue](https://github.com/tlverse/tmle3mopttx/issues).

---

## License

The contents of this repository are distributed under the GPL-3 license.
See file `LICENSE` for details.

-----

## References

