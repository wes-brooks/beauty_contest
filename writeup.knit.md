---
title: "Comparing methods for predicting health advisories for beach water"
author: "Wesley Brooks, Rebecca Carvin, Steve Corsi"
output: pdf_document
bibliography: ../references/beautycontest.bib
---

# Abstract
Pithy, concise and informative. May bring the reader to tears due to the beauty of it.

# Introduction

With input from the US Environmental Protection Agency, the state of Wisconsin has established regulatory standards for beach water quality, which states that a warning is to be posted when the concentration of E. coli exceeds $235$ CFU / $100$ mL. (Is that statement correct?) The goal of modeling the bacterial concentration is to predict in advance when the concentration will exceed the limit.

# Methods

The availability of large data sets for building regression models to predict the bacterial counts in beach water is both an opportunity and a challenge. 

## Data Sources

Possibly move this to the end of the section

Which sites

Where are they

What specific sources sources of data (plug EnDDAT)

Will include a map and tables

## Definitions

At any site, denote the predictor variables by $X$, which is an $n\times p$ matrix where $n$ is the number of observations and $p$ is the number of predictors. The vector of $n$ observations of bacterial concentration is denoted $y$. The mathematical model relating $y$ to $X$ is the function $\mu(X, y)$. Denote the regulatory standard by $\delta$ and the decision threshold by $\hat{{\delta}}$.

## Listing of specific statistical techniques

Fourteen different regression modeling techniques were considered. Each technique uses one of five modeling algorithms: GBM, the adaptive lasso, the genetic algorithm, PLS, or sparse PLS. Each technique is applied to either continuous or binary regression and to either variable selection and model estimation, or variable selection only.

#### Continuous vs. binary regression

The goal of predicting exceednaces of the water quality standard is approached in two ways: one is to predict the bacterial concentration and then compare the prediction to a threshold, which is referred to as continuous modeling. The other is referred to as binary modeling, in which we predict the state of the binary indicator $z_{i}$:

$$ z_{i}=I(y_{i}>\delta) $$

The indicator is coded as zero when the concetration is below the regulatory standard and one when the concentration exceeds the standard. All of the binary modeling techniques herein use logistic regression [@Hosmer-Lemeshow-2004]. Binary regression methods are indicated with a (b).

#### Weighting of observations in binary regression

A weighting scheme was implemented for some of the binary regression techniques. In the weighting scheme, observations were given weights $w_{i}$ where:

$$ w_{i}=    (y_{i}-\delta)/\hat{{sd}}(y)
\hat{{sd}}(y)=	\sqrt{\sum_{i=1}^{n}(y_{i}-\bar{{y}})^{2}/n}
\bar{{y}}=	\sum_{i=1}^{n}y_{i}/n $$


That is, the weights are equal to the number of standard deviations that the observed concentration lies from the regulatory threshold $\delta$. Any technique that was implemented with this weighting scheme was separately implemented without any weighting of the observations. The methods that weight the observations are indicated with a (w).

#### Selection-only methods

The contest investigated whether certain modeling methods should be used only to select covariates. Once the predictor variables were selected, the regression model using those predictors were estimated using ordinary least squares for the continuous methods, or ordinary logistic regression for the binary methods. Selection-only methods are indicated by an (s).

### GBM

A gradient boosting machine (GBM) model is a so-called random forest model - a collection of many regression trees [@Friedman-2001]. Prediction is done by averaging the outputs of the trees. Two GBM-based techniques are explored - we refer to them as GBM-OOB and GBM-CV. The difference is in how the optimal number of trees is determined - GBM-CV selects the number of trees in a model using leave-one-out CV, while GBM-OOB uses the so-called out-of-bag error estimate. The CV method is much slower (it has to construct as many random forests as there are observations, while the OOB method only requires computing a single random forest) but GBM-CV should more accurately estimate the prediction error.

All the GBM-OOB and GBM-CV models were estimted using the `gbm` package in `R`, using $10000$ trees, shrinkage parameter $0.0005$, minimum $5$ observations per node, tree depth $5$, and bagging fraction $0.5$ [@.]

Number of trees: 10000

Shrinkage parameter: 0.0005

Minimum observations per node: 5

Depth of each tree: 5

Bagging fraction: 0.5

### Adaptive Lasso

The adaptive lasso (AL) is a penalized regression method that simultaneously selects relevant predictors and estimates their coefficients [@Zou-2006]. The penalty part of an AL model is proportional to the sum of absolute values of the coefficients - covariates are dropped from the model when they incur a penalty larger than the amount by which they improve the model fit. For continuous response, AL estimates $\hat{\bm{\beta}}$ to minimize the penalized sum of squared residuals:

$$ \sum_{i=1}^n (y_i - X_i \beta)^2 + \lambda \sum_{j=1}^p \frac{|\beta_{j}|}{|\tilde{\beta}_{j}|^{\gamma}}, $$

where $\lambda$ is a tuning parameter and $\tilde{\bm{\beta}}$ is a consistent estimate of the regression coefficients. For binary modeling, AL maximizes the penalized log-likelihood

$$ \sum_{i=1}^n \left[-(1 - y_i) X_i \beta - \log \left\{ 1 + \exp\left(-X_i \beta \right) \right\} \right] + \lambda \sum_{j=1}^p \frac{|\beta_j|}{|\tilde{\beta}_j|^{\gamma}}, $$

where, as for continuous response, $\tilde{\bm{\beta}}$ is a consistent estimate of the regression coefficients. For the contest, $\gamma=1$, the $\tilde{\bm{\beta}}$ are estimated individually by a univariate linear or logistic regression (it is necessary to estimate the coefficients individually because there are usually more covariates than observations), and the AL tuning parameter $\lambda$ is selected to minimize the AICc [@Hurvich-Simonoff-Tsai-1998].

### Genetic algorithm

The genetic algorithm is a variable-selection method that works by analogy to natural selection, where so-called chromosomes represent regression models [@Fogel-1998]. A variable is included in the model if the corresponding element of the chromosome is one, but not otherwise. Chromosomes are produced in successive generations, where the first generation is produced randomly and subsequent generations are produced by combining chromosomes from the current generation, with additional random drift. The chance that a chromosome in the current generation will produce offspring in the next generation is an increasing function of its fitness. The fitness of each chromosome is calculated by the corrected Akaike Information Criterion (AICc) [@Akaike-1973; @Hurvich-Tsai-1989].

The implementations in this study used 100 generations, with each generation consisting of 200 chromosomes. The genetic algorithm method (GA) is the default for linear regression modeling in Virtual Beach [@Cyterski-Brooks-Galvin-Wolfe-Carvin-Roddick-Fienen-Corsi-2013]. This study also investigates two genetic algorithm methods for logistic regression: one weighted (GA-logistic-weighted) and one unweighted (GA-logistic-unweighted).

### PLS

Partial least squares (PLS) regression is a tool for building regression models with many covariates [@Wold-Sjostrum-Eriksson-2001]. PLS works by decomposing the covariates into mutually orthogonal components, with the components then used as the variables in a regression model. This is similar to principal components regression (PCR), but the way PLS components are chosen ensures that they are aligned with the model output. On the other hand, PCR is sometimes criticised for decomposing the covariates into components that are unrelated to the model's output. To use PLS, one must decide how many components to use in the model. This study follows the method described in [@Brooks-Fienen-Corsi-2013], using the PRESS statistic to select the number of components.

### SPLS

Sparse PLS (SPLS) combines the orthogonal decompositions of PLS with the sparsity of lasso-type variable selection [@Chun-Keles-2007]. To do so, SPLS uses two tuning parameters: one that controls the number of orthogonal components and one that controls the lasso-type penalty. The optimal parameters are those that minimize the mean squared prediction error (MSEP) over a two-dimensional grid search. The MSEP is estimated by 10-fold cross-validation.

## Implementation for beach regression

The response variable for our continuous regression models is the base-10 logarithm of the *E. coli* concentration. For the binary regression models, the response variable is an indicator of whether the concentration exceeds the regulatory threshold $\delta=235$ CFU/mL. Transformations were applied to some of the data during pre-processing: the beach water turbidity and the discharge of tributaries near each beach were log-transformed, and rainfall variables were all square root transformed.





















