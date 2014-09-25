---
title: "Comparing methods for predicting health advisories for beach water"
author: "Wesley Brooks, Rebecca Carvin, Steve Corsi, Mike Fienen"
output:
    pdf_document:
        fig_caption: true  
        number_sections: true
bibliography: ../references/beautycontest.bib
---

*COMMENT:* General comments:
1. Very nice work here. The writing is concise and clear. The organization is well done. Most comments are just minor issues or some things that might help with clarification.
2. Need to be a bit more consistent with acronyms. Once you define an acronym, use it throughout. There are cases where the full spelling and the acronym are mixed throughout the manuscript.
3. Some of the table and figure references are muddled up in the linking process.
4. After all is complete, I wondered if we should include reference to virtual beach and the methods that are included earlier in the manuscript. I am not convinced either way yet, but it would be worth a little discussion as to where it might be appropriate. Maybe a mention in the methods when they are being described? It might also be worth mentioning that VB only had OLS/GA options until recently. This would fit in the intro section where it is mentioned that OLS is the most common method, and would serve to strengthen that statement.

# Abstract
Pithy, concise and informative. May bring the reader to tears due to the beauty of it.

# Introduction
Fecal indicator bacteria (FIB) in beach water are often used to indicate contamination by harmful pathogens [@Cabelli:1979lb; @Wade:2006qc; @Wade:2008yi; @Fleisher:2010xo]. The United States Environmental Protection Agency (USEPA) has established, through epidemiological studies, that FIB concentration is associated with human health outcomes [@Cabelli:1983od; @Dufour:1984yn; @USEPA:ecs]. Accordingly, the state of Wisconsin has established regulatory standards for beach water quality, stating that a beach should be posted with a swimmer's advisory when the concentration of the FIB *Escherichia coli* exceeds $235$ colony forming units (CFU) / $100$ mL [@USEPA-2012; @WDNR-2012]. Traditional analysis methods for FIB concentration requires 18--24 hours for culturing a sample, so the decision to post an advisory is often made based on the previous day's FIB concentration, which is the so-called "persistence model" for beach management [@Agency:2007lj]. Previous research has shown that the concentration of FIB in beach water can vary substantially during the 18-24 h analysis period, with the result that the persistence model often provides incorrect information for posting warnings [@Whitman:2004wv; @Whitman:2008nb]. Thus, at beaches managed using the persistence model, the public is sometimes exposed to health risks or unnecessarily deprived of recreation opportunities.

In order to have more immediate knowledge of the FIB concentration, it is now common to use regression models that "nowcast" the FIB concentration based on some easily observed surrogate covariates, e.g. turbidity and running 24 h rainfall total [@Brandt:2006gj; @Olyphant:2004yq]. Numerous regression techniques have been used to generate nowcast models of FIB concentration. The techniques include ordinary least squares (OLS) [@Nevers:2005ln; @Francy:2007yv], partial least squares (PLS) [@Hou:2006nf; @Brooks-Fienen-Corsi-2013], logistic regression [@Waschbusch:2004bd; @Jin:2006tr], decision trees [@Stidson-2012], random forests [@Parkhurst:2005zf; @Jones-Liu-Dorovitch-2012], and artificial neural networks [@Kashefipour-Lin-Falconer-2005; @He:2008jx]. A thorough review of the regression techniques being used in nowcast models for FIB concentration is provided by @deBrauwere-Koffi-Servais-2014.

Ordinary least squares regression is the most commonly used regression technique in the nowcast models [@deBrauwere-Koffi-Servais-2014]. However, OLS is well-known for drawbacks like overfitting, difficulty of variable selection, and the inflexibility of its linear modeling structure [@Ge:2007ou]. The literature suggests that many regression techniques have been successfully used for nowcast modeling, but due to differences in such factors as local conditions, data handling, and performance validation, it is not possible to identify the best regression technique for nowcast modeling by comparing different models at different sites. In this study, fourteen regression techniques are evaluated in nowcast models at seven Wisconsin beaches over four years of data. The results are compared to identify the techniques that more accurately predict instances when a swimmer's advisory should be posted. This "beauty contest"--making comparisons of multiple methods in multiple settings--is designed to provide insights that may be lost when comparing individual methods at single sites.

The remainder of the paper is organized as follows: in the next section we discuss data collection and handling, describe the regression techniques, and explain how the comparisons were made. Next, we present the results of comparing the methods by several metrics including: area under the ROC curve; predictive error sum of squares; and raw number of correct/incorrect predictions. Finally, we discuss what the comparison suggests about which are the best choices for a regression technique in a nowcast model.

# Methods

The availability of large data sets for building regression models to predict the bacterial counts in beach water is both an opportunity and a challenge. 

## Data Sources

Possibly move this to the end of the section

Which sites

Where are they

What specific sources sources of data (plug EnDDAT)

Will include a map and tables

Concentration of Escherichia coli (E. coli) was measured at each beach 4 times each week for 12 to 14 weeks each swimming season between Memorial Day and Labor Day from 2010 through 2013. Samples were collected from the center of the beach swim area, 12 inches below the water surface where total water depth was 24 inches. All samples were quantified using Colilert®, which gives the most probable number (MPN) of E. coli colony forming units (CFU) and is read after 24 hours of incubation. Further explanation of sampling protocol and technique is available here (busse must have a paper on this).

Independent variables were compiled from a variety of sources including online datasets and manual measurements collected at the sites. Online datasets were all accessed using Environmental Data Discovery and Transformation (EnDDaT), a web service that accesses data from a variety of data sources, compiles and processes the data, and performs common transformations (cite webpage/cida). Three datasets were accessed: National Water Information System (NWIS), North Central River Forecasting Center (NCRFS), and Great Lakes Costal Forecasting System (GLCFS). Variables available from these datasets included: river discharge, precipitation, lake current vectors, wave height, wave direction, lake level, water temperature, air temperature, wind vector, and percent cloud cover. Transformations computed using EnDDaT were mean, minimum, maximum, difference, sum, and standard deviation. These were computed when they described an aspect that might affect E. coli colony growth. For example standard deviation of water temperature indicated if water temperature was consistent or highly variable, which would make conditions favorable or not for colony formation. 12 hour sum of rainfall indicated if there had recently been a rain event better, and 6 hour average cloud cover would approximate the effect of UV light breaking down colonies during a sunny day. Exploration of how independent variables might correlate to E. coli included several transformations and several time periods for each of the 10 basic (root?) variables listed above. The total number of web-service independent variables ranged from 76 (Kreher) to 158 (Neshotah).

Manual variables had the benefit of being measured where E. coli samples were collected, but did not have the hourly time-resolution, or ability to be gathered remotely. Turbidity, estimated wave height, number of birds present, number of people present, amount of algae floating in the swim area and on the beach, specific conductance, water and air temperature, wind direction and speed, were among the variables gathered manually. Many of these variables were dropped from the datasets because of missing values, or questionable reliability. Every beach had manual turbidity measurements in the beauty contest dataset.

## Definitions

At any site, let $\bm{y}=(y_1, \dots, y_n)$ be the vector of FIB concentration measurements, let $n$ be the number of observations, and let $p$ be the number of explanatory variables. The beach action value (BAV) of $235$ CFU / $100$ mL was recommended by the USEPA as the "do not exceed" threshold in order to limit gastrointestinal illnesses among those coming into contact with beach water to 36 cases per 1000 [@USEPA-2012]. The BAV is represented symbolically by $\delta$. Define an exceedance as a FIB measurement that exceeds the BAV. Conversely, a nonexceedance is a FIB measurement that does not exceed the BAV.

Applying a model to data that was not used to estimate the model produces predictions, which are denoted by a tilde (e.g., $\tilde{y}_i$). On the other hand applying the model to the same data as was used to estimate the model produces fitted values, which are denoted by a hat (e.g., $\hat{y}_j$). A predicted exceedance is when a model predicts that the FIB concentration exceeds the BAV. This is not the same as $\tilde{y}_i > \delta$ because predictions are compared to a decision threshold $\hat{\delta}$ rather than to the BAV $\delta$. The decision threshold $\hat{\delta}$ is a parameter that can be adjusted to tune the predictive performance. For instance, increasing the decision threshold reduces the number of false positives but increases the number of false negatives. Setting the decision threshold is an important detail that is discussed in Section 4.4.

## Statistical techniques evaluated

Fourteen different regression modeling techniques were considered (Table 1). Each technique uses one of five modeling algorithms: the gradient boosting machine (GBM), the adaptive Lasso (AL), the genetic algorithm (GA), partial least squares (PLS), or sparse PLS (SPLS). Each technique is applied to either continuous or binary regression and to either variable selection and model estimation, or variable selection only.

#### Continuous vs. binary regression

The goal of predicting exceednaces of the water quality standard is approached in two ways: one is to predict the bacterial concentration and then compare the prediction to a threshold, which is referred to as continuous modeling. The other is referred to as binary modeling, in which we predict the state of the binary indicator $z_{i}$:

$$ z_{i}=\left\{ \begin{array}{c}
I\left(\tilde{y}_{i}<\delta\right) = 0\\
I\left(\tilde{y}_{i}\ge\delta\right) = 1
\end{array}\right. $$

where $\tilde{y}_i$ is the predicted concentration. The indicator is coded as zero when the concetration is below the regulatory standard and one when the concentration exceeds the standard. All of the binary modeling techniques herein use logistic regression [@Hosmer-Lemeshow-2004]. Binary regression methods are indicated with a (b).

#### Weighting of observations in binary regression

The concentration of *E. coli* in the water at a single beach on a single day can be subject to a large degree of spatiotemporal heterogeneity [@Whitman:2004pc]. Thus, when the concentration in a sample is observed to fall near the BAV, there is considerable uncertainty as to whether an independent sample from the same date and location would or would not exceed the BAV. A weighting scheme for the binary regression techniques was designed to reflect this ambiguity by giving more weight to observations far from the BAV. In the weighting scheme, observations were given weights $w_i$ for $i=1,\dots,n$, where

$$
    \begin{aligned}
        w_i &= (y_i - \delta) / \hat{\rm{sd}}(y)\\
        \hat{\rm{sd}}(y) &= \sqrt{\sum_{i=1}^n (y_i - \bar{y})^2 / n}\\
        \bar{y} &= \sum_{i=1}^n y_i / n.
    \end{aligned}
$$

That is, the weights are equal to the number of standard deviations that the observed concentration lies from the regulatory threshold. Any technique that was implemented with this weighting scheme was separately implemented without any weighting of the observations. The methods using the weighting scheme are indicated by (w).

#### Selection-only methods

The contest investigated whether certain modeling methods should be used only to select covariates. Once the covariates were selected, the regression model using those covariates was estimated using ordinary least squares for the continuous methods, or ordinary logistic regression for the binary methods. Selection-only methods are indicated by an (s).

*COMMENT:* I agree with Mike's comments on a table of the methods used.

### GBM

A GBM model is a so-called random forest model - a collection of many regression trees, each fitted to a randomly drawn subsample of the training data [@Friedman-2001]. Prediction is done by averaging the outputs of the trees. Two GBM-based techniques are explored - we refer to them as GBM-OOB and GBM-CV. The difference is in how the optimal number of trees is determined - GBM-CV selects the number of trees in a model using leave-one-out cross validation (CV), while GBM-OOB uses the so-called out-of-bag error estimate, where the predictive error of each tree is estimated by its predictive error over the observations that were left out when fitting the tree. In contrast, the predictive error of CV is estimated from observations that are left out from the training data altogether, and are therefore not used in the fitting of any trees. The CV method is much slower (it has to construct as many random forests as there are observations, while the OOB method only requires computing a single random forest).  However, GBM-CV should more accurately estimate the prediction error.

### Adaptive Lasso

The least absolute shrinkage and selection operator (Lasso) is a penalized regression method that simultaneously selects relevant covariates and estimates their coefficients [@Tibshirani-1996]. The AL is a refinement of the Lasso that possesses the so-called "oracle" properties of asymptotically selecting exactly the correct covariates and estimating them as accurately as would be possible if their identities were known in advance [@Zou-2006]. To use the AL for prediction requires selecting a tuning parameter. For the contest, the AL tuning parameter $\lambda$ is selected to minimize the corrected Akaike Information Criterion (AICc) [@Akaike-1973; @Hurvich-Simonoff-Tsai-1998].

### Genetic algorithm

Here, the GA is used to select variables for either an OLS or a logistic regression model. By analogy to natural selection, so-called chromosomes in the GA represent regression models [@Fogel-1998]. A covariate is included in the model if the corresponding element of the chromosome is one, but not otherwise. Chromosomes are produced in successive generations, where the first generation is produced randomly and subsequent generations are produced by combining chromosomes from the current generation, with additional random drift. The chance that a chromosome in the current generation will produce offspring in the next generation is an increasing function of its fitness. The fitness of each chromosome is calculated by the AICc.

### PLS

Partial least squares (PLS) regression is a tool for building regression models with many covariates [@Wold-Sjostrum-Eriksson-2001]. PLS works by decomposing the covariates into mutually orthogonal components, with the components then used as the covariates in a regression model. This is similar to principal components regression (PCR), but the way PLS components are chosen ensures that they are aligned with the model output, whereas PCR is sometimes criticised for decomposing the covariates into components that are unrelated to the model's output. To use PLS, one must decide how many components to use in the model. This study follows the method described in [@Brooks-Fienen-Corsi-2013], using the PRESS statistic to select the number of components.

### SPLS

Sparse PLS (SPLS) combines the orthogonal decompositions of PLS with the sparsity of Lasso-type variable selection [@Chun-Keles-2007]. To do so, SPLS uses two tuning parameters: one that controls the number of orthogonal components and one that controls the Lasso-type penalty. The optimal parameters are those that minimize the mean squared prediction error (MSEP) over a two-dimensional grid search. The MSEP is estimated by 10-fold cross-validation.


-----------------------------------------------------------------------------------------------------------------------------
                                                               Selection   
Name         Algorithm                     Binary   Weighted   Only       Note
----------- ----------------------------- -------- ---------- ----------- ---------------------------------------------------
GBM-OOB     Gradient boosting                                             Out-of-bag estimate of optimal trees

GBM-CV      Gradient boosting                                             Cross-validation estimate of optimal trees

AL          Adaptive Lasso                                                Select tuning parameter by AICc

AL (s)      Adaptive Lasso                                       X        Select tuning parameter by AICc

AL (b)      Adaptive Lasso                   X                            Select tuning parameter by AICc

AL (b,w)    Adaptive Lasso                   X          X                 Select tuning parameter by AICc

AL (s,b)    Adaptive Lasso                   X                   X        Select tuning parameter by AICc

AL (s,b,w)  Adaptive Lasso                   X          X        X        Select tuning parameter by AICc

GA          Genetic algorithm                                             Fitness calculated as AICc

GA (b)      Genetic algorithm                X                            Fitness calculated as AICc

GA (b,w)    Genetic algorithm                X          X                 Fitness calculated as AICc

PLS         Patrial least squares                                         Select components to minimize PRESS

SPLS        Sparse partial least squares                                  Cross-validation used to select tuning parameters

SPLS (s)    Sparse partial least squares                         X        Cross-validation used to select tuning parameters
---------- ------------------------------  -------- --------- ----------- ----------------------------------------------------
[Table 1](#table:methods): Comprehensive list of the modeling methods analyzed in this study. Listed for each method are the method's abbreviation, the algorithm used by the method, and indicators of whether the method 


## Data transformations for beach regression

The response for our continuous regression models is the base-10 logarithm of the *E. coli* concentration. For the binary regression models, the response is an indicator of whether the concentration exceeds the regulatory threshold $\delta=235$ CFU/mL. Transformations were applied to some of the data during pre-processing: the beach water turbidity and the discharge of tributaries near each beach were log-transformed, and rainfall variables were all square root transformed. These transformations were based on the performance of previous studies (REFS: Francy? PLS paper? Nevers? Others?) and applied to all datasets equally. 





















