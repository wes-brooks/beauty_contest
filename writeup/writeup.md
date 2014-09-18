---
title: "Comparing methods for predicting health advisories for beach water"
author: "Wesley Brooks, Rebecca Carvin, Steve Corsi, Mike Fienen"
output:
    pdf_document:
        fig_caption: true   
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

## Definitions

At any site, denote the covariates, or explanatory variables, by $X$, which is an $n \times p$ matrix where $n$ is the number of observations and $p$ is the number of covariates. The vector of $n$ observations of bacterial concentration is denoted $y$. Denote the regulatory standard $\delta$ and the decision threshold $\hat{\delta}$. The decision threshold $\hat{\delta}$--described in more detail below--is used to balance the conclusions of exceedance or nonexceedance of $\delta$. Structural error inherent to the modeling process results in bias. This bias can cause poor performance with respect to predicted actual concentration in cases with a continuous response, but adjusting the decision threshold to account for the bias can improve exceedance calcualtions. 

## Statistical techniques evaluated

-------------------------------------------------------------------------
                                                               Selection 
Name         Algorithm                     Binary   Weighted   Only
----------- ----------------------------- -------- ---------- ----------- 
GBM-OOB     Gradient boosting         

GBM-CV      Gradient boosting

AL          Adaptive lasso

AL (s)      Adaptive lasso                                       X

AL (b)      Adaptive lasso                   X                    

AL (b,w)    Adaptive lasso                   X          X          

AL (s,b)    Adaptive lasso                   X                   X

AL (s,b,w)  Adaptive lasso                   X          X        X

GA          Genetic algorithm

GA (b)      Genetic algorithm                X

GA (b,w)    Genetic algorithm                X          X

PLS         Patrial least squares

SPLS        Sparse partial least squares

SPLS (s)    Sparse partial least squares                         X
---------- ------------------------------  -------- --------- -----------
[Table 2](#table:methods): The methods that were compared in this study.

Fourteen different regression modeling techniques were considered. Each technique uses one of five modeling algorithms: gradient boosting machine (GBM), the adaptive lasso (AL), ordinary least squares (OLS) using the genetic algorithm, partial least squares (PLS), or sparse PLS. Each technique is applied to either continuous or binary regression and to either variable selection and model estimation, or variable selection only.

*COMMENT:* We should include mention of OLS being used in the genetic algorithm. This is stated as the most common method, so should be very obvious right from the start. I have made a suggested change above.

#### Continuous vs. binary regression

The goal of predicting exceednaces of the water quality standard is approached in two ways: one is to predict the bacterial concentration and then compare the prediction to a threshold, which is referred to as continuous modeling. The other is referred to as binary modeling, in which we predict the state of the binary indicator $z_{i}$:

$$ z_{i}=\left\{ \begin{array}{c}
I\left(\tilde{y}_{i}<\delta\right) = 0\\
I\left(\tilde{y}_{i}\ge\delta\right) = 1
\end{array}\right. $$

where $\tilde{y}_i$ is the predicted concentration. The indicator is coded as zero when the concetration is below the regulatory standard and one when the concentration exceeds the standard. All of the binary modeling techniques herein use logistic regression [@Hosmer-Lemeshow-2004]. Binary regression methods are indicated with a (b).

#### Weighting of observations in binary regression

A weighting scheme was implemented for some of the binary regression techniques. In the weighting scheme, observations were given weights $w_i$ where:

$$
    \begin{aligned}
        w_i &= (y_i - \delta) / \hat{\rm{sd}}(y)\\
        \hat{\rm{sd}}(y) &= \sqrt{\sum_{i=1}^n (y_i - \bar{y})^2 / n}\\
        \bar{y} &= \sum_{i=1}^n y_i / n
    \end{aligned}
$$

That is, the weights are equal to the number of standard deviations that the observed concentration lies from the regulatory threshold. Any technique that was implemented with this weighting scheme was separately implemented without any weighting of the observations. The methods that weight the observations are indicated with a (w).

#### Selection-only methods

The contest investigated whether certain modeling methods should be used only to select covariates. Once the covariates were selected, the regression model using those covariates was estimated using ordinary least squares for the continuous methods, or ordinary logistic regression for the binary methods. Selection-only methods are indicated by an (s).

*COMMENT:* I agree with Mike's comments on a table of the methods used.

### GBM

A gradient boosting machine (GBM) model is a so-called random forest model - a collection of many regression trees, each fitted to a randomly drawn subsample of the training data [@Friedman-2001]. Prediction is done by averaging the outputs of the trees. Two GBM-based techniques are explored - we refer to them as GBM-OOB and GBM-CV. The difference is in how the optimal number of trees is determined - GBM-CV selects the number of trees in a model using leave-one-out cross validation (CV), while GBM-OOB uses the so-called out-of-bag error estimate, where the predictive error of each tree is estimated by its predictive error over the observations that were left out when fitting the tree. In contrast, the predictive error of CV is estimated from observations that are left out from the training data altogether, and are therefore not used in the fitting of any trees. The CV method is much slower (it has to construct as many random forests as there are observations, while the OOB method only requires computing a single random forest).  However, GBM-CV should more accurately estimate the prediction error.

### Adaptive Lasso

The least absolute shrinkage and selection operator (Lasso) is a penalized regression method that simultaneously selects relevant covariates and estimates their coefficients [@Tibshirani-1996]. The adaptive lasso is a refinement of the Lasso that possesses the so-called "oracle" properties of asymptotically selecting exactly the correct covariates and estimating them as accurately as would be possible if their identities were known in advance [@Zou-2006]. To use the AL for prediction requires selecting a tuning parameter. For the contest, the AL tuning parameter $\lambda$ is selected to minimize the corrected Akaike Information Criterion (AICc) [@Akaike-1973; @Hurvich-Simonoff-Tsai-1998].

### Genetic algorithm

The genetic algorithm is a variable-selection method that works by analogy to natural selection, where so-called chromosomes represent regression models [@Fogel-1998]. A covariate is included in the model if the corresponding element of the chromosome is one, but not otherwise. Chromosomes are produced in successive generations, where the first generation is produced randomly and subsequent generations are produced by combining chromosomes from the current generation, with additional random drift. The chance that a chromosome in the current generation will produce offspring in the next generation is an increasing function of its fitness. The fitness of each chromosome is calculated by the AICc.

### PLS

Partial least squares (PLS) regression is a tool for building regression models with many covariates [@Wold-Sjostrum-Eriksson-2001]. PLS works by decomposing the covariates into mutually orthogonal components, with the components then used as the covariates in a regression model. This is similar to principal components regression (PCR), but the way PLS components are chosen ensures that they are aligned with the model output, whereas PCR is sometimes criticised for decomposing the covariates into components that are unrelated to the model's output. To use PLS, one must decide how many components to use in the model. This study follows the method described in [@Brooks-Fienen-Corsi-2013], using the PRESS statistic to select the number of components.

### SPLS

Sparse PLS (SPLS) combines the orthogonal decompositions of PLS with the sparsity of lasso-type variable selection [@Chun-Keles-2007]. To do so, SPLS uses two tuning parameters: one that controls the number of orthogonal components and one that controls the lasso-type penalty. The optimal parameters are those that minimize the mean squared prediction error (MSEP) over a two-dimensional grid search. The MSEP is estimated by 10-fold cross-validation.

## Data transformations for beach regression

The response for our continuous regression models is the base-10 logarithm of the *E. coli* concentration. For the binary regression models, the response is an indicator of whether the concentration exceeds the regulatory threshold $\delta=235$ CFU/mL. Transformations were applied to some of the data during pre-processing: the beach water turbidity and the discharge of tributaries near each beach were log-transformed, and rainfall variables were all square root transformed. These transformations were based on the performance of previous studies (REFS: Francy? PLS paper? Nevers? Others?) and applied to all datasets equally. 









## Cross Validation

Our assessment of the modeling techniques is based on their performance in predicting exceedances of the regulatory standard. Two types of cross validation were used to measure the performance in prediction: leave-one-out (LOO) and leave-one-year-out (LOYO). In LOO CV, one observation is held out for validation while the rest of the data is used to train a model. The model is used to predict the result of that held out observation, and the process is repeated for each observation. Each cycle of LOYO CV holds out an entire year's worth of data for validation instead of a single observation. It is intended to approximate the performance of the modeling technique under a typical use case: a new model is estimated before the start of each annual beach season and then used for predicting exceedances during the season. The LOYO models in this study were estimated using all the available data except for the held out year, even that from future years. So for instance the 2012 models were estimated using the 2010-2011 and 2013 as training data.

Some methods also used CV internally to select tuning parameters. In those cases the internal CV was done using only the model data, and never looking at the held-out observation(s). This process is separate from - and does not affect - the CV to assess predictive performance.


## Comparing methods, and quantifying uncertainty in the ranks

Results were compiled into one table for each site, such as Table 1, which contains the results of running the contest at Hika. Each observation corresponds to a row in the table. The results table has a column for the observed log *E. coli* concentration and, for each method, columns for the predicted concentration by LOO CV and by LOYO CV. From the table, we can calculate the predictive error sum of squares (PRESS) and the area under the receiver operating characteristic (ROC) curve (AUROC), which are the statistics we use to summarize performance of the modeling methods.

-----------------------------------------------------------
                 PLS     PLS              SPLS    SPLS      
 Row   Actual    (LOO)   (LOYO)   \dots   (LOO)   (LOYO) 
----- --------  ------- -------- ------- ------- -------- 
1      2.54      2.35     2.22   \dots   2.29    2.55 

2      2.59      1.87     1.79   \dots   1.91    1.23

\vdots \vdots    \vdots   \vdots \dots   \vdots  \vdots

166    1.57      1.93     2.06   \dots   1.83    2.07 

167    3.38      1.84     2.01   \dots   1.80    1.71
-----  ------    ------   ------ -----   ------  ------ 
[Table 1](#table:hika-results): The results table from Hika.

*COMMENT:* Need a table caption here and reference to it in the text.

To identify which modeling methods have the best performance across all sites, the summary statistics at each site were converted to ranks. We report the mean rank of each method across the sites. Uncertainty in the rankings is quantified by the bootstrap. Since PRESS and AUROC are functions of the results tables, the bootstrap procedure is carried out by resampling the rows of each results table and recalculating the ranks for each bootstrap sample. We used $1001$ bootstrap samples of each results table in the analysis that follows.

# Results

## AUROC

The ROC curve is an assessment of how well predictions are sorted into exceedances and nonexceedances of a threshold. The AUROC averages the model's performance over the range of possible thresholds. A model which perfectly separates exceedances from non-exceedances in prediction has an AUROC of one, while a model that predicts exceedances no better than a coin flip has an AUROC of $0.5$.

*COMMENT:* The ranks are opposite of what I typically consider as ranks--usually I would consider 1 to be the best ranking. It is clear enough in the title that higher is better and certainly makes more sense visually to see the best method with the largest bar. Interesting that the lowest ranks are between 4 and 5, indicating that the lower ~2/3 ranked methods change places a fair bit 

*COMMENT:* These two tables could be made into one two-section table to save a bit of space. They do logically go together well.

![Mean ranking of the methods by area under the ROC curce (AUROC) across all seven sites (higher is better). The error bars are 90% confidence intervals computed by the bootstrap. At left are the AUROC rankings from the leave-one-year-out cross validation (a), at right are the AUROC rankings from the leave-one-out cross validation (b).](figure/auroc-barchart.png) 

\begin{table}[ht]
\centering
\scalebox{0.73}{
\begin{tabular}{rccccccccccccc}
  \hline
 & \begin{tabular}{c}GBM- \\ OOB\end{tabular} & \begin{tabular}{c}AL\end{tabular} & \begin{tabular}{c}AL \\ (b,w)\end{tabular} & \begin{tabular}{c}AL \\ (s)\end{tabular} & \begin{tabular}{c}AL \\ (b)\end{tabular} & \begin{tabular}{c}PLS\end{tabular} & \begin{tabular}{c}SPLS\end{tabular} & \begin{tabular}{c}SPLS \\ (s)\end{tabular} & \begin{tabular}{c}AL \\ (b,s)\end{tabular} & \begin{tabular}{c}AL \\ (b,w,s)\end{tabular} & \begin{tabular}{c}GA\end{tabular} & \begin{tabular}{c}GA \\ (b,w)\end{tabular} & \begin{tabular}{c}GA \\ (b)\end{tabular} \\ 
  \hline
GBM-CV & 0.82 & 0.82 & 0.91 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 \\ 
  GBM-OOB &  & 0.73 & 0.82 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 \\ 
  AL &  &  & 0.73 & 0.91 & 1.00 & 0.91 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 \\ 
   \hline
\end{tabular}
}
\caption{Under leave-one-year-out cross validation, frequency of the mean AUROC rank of GBM-OOB, GBM-CV, or AL (in the rows) exceeding that of the other methods (in the columns).} 
\label{table:auroc.pairs.annual}
\end{table}
\begin{table}[ht]
\centering
\scalebox{0.73}{
\begin{tabular}{rccccccccccccc}
  \hline
 & \begin{tabular}{c}GBM- \\ OOB\end{tabular} & \begin{tabular}{c}AL\end{tabular} & \begin{tabular}{c}AL \\ (b,w)\end{tabular} & \begin{tabular}{c}AL \\ (s)\end{tabular} & \begin{tabular}{c}GA\end{tabular} & \begin{tabular}{c}AL \\ (b,w,s)\end{tabular} & \begin{tabular}{c}SPLS\end{tabular} & \begin{tabular}{c}SPLS \\ (s)\end{tabular} & \begin{tabular}{c}PLS\end{tabular} & \begin{tabular}{c}AL \\ (b)\end{tabular} & \begin{tabular}{c}AL \\ (b,s)\end{tabular} & \begin{tabular}{c}GA \\ (b,w)\end{tabular} & \begin{tabular}{c}GA \\ (b)\end{tabular} \\ 
  \hline
GBM-CV & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 \\ 
  GBM-OOB &  & 1.00 & 0.91 & 1.00 & 1.00 & 0.91 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 \\ 
  AL &  &  & 0.73 & 1.00 & 1.00 & 0.91 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 & 1.00 \\ 
   \hline
\end{tabular}
}
\caption{Under leave-one-out cross validation, frequency of the mean AUROC rank of GBM-OOB, GBM-CV, or AL (in the rows) exceeding that of the other methods (in the columns).} 
\label{table:auroc.pairs}
\end{table}

The mean LOO and LOYO ranks for all the methods are plotted in Figure 1. The three top-ranked methods were GBM-CV, GBM-OOB, and AL. In order to facilitate a pairwise comparison between modeling methods, Tables 2 (for the leave-one-year-out analysis) and 3 (for the leave-one-out analysis) show the frequency that the mean AUROC rank of GBM-OOB, GBM-CV, or AL exceeded each of the other modeling methods.

## PRESS

While AUROC quantifies how well a model sorts exceedances and non-exceedances, PRESS measures how accurrately a model's predictions match the observed bacterial concentration. The PRESS can only be computed for continuous regression methods. Let the model's predictions be denoted $\tilde{y}_i$ and letting the actual observed bacterial concentrations be denoted $y_{i}$ for $i=1,\dots,n$ where $n$ is the total number of predictions. Then PRESS is computed as follows:
    
$$\text{PRESS}=\sum_{i=1}^{n}\left(\tilde{y}_{i}-y_{i}\right)^{2}.$$


The PRESS statistic is of interest because a good model should accurately predict the bacterial concentration, but in the current application, AUROC is a more important metric of model performance than the PRESS because it directly measures the ability of a model to separate exceedances from non-exceedances. That said, we expect the two statistics to usually agree on which modeling methods perform best.

The rankings of the methods by PRESS are plotted in Figure 2. The top three techniques under both LOO and LOYO analysis were GBM-CV, GBM-OOB, and AL. The pairwise comparison of modeling methods by PRESS are in Tables 4 (for the leave-one-year-out analysis) and 5 (for the leave-one-out analysis).

![Mean ranking of the methods by predictive error sum of squares (PRESS) across all sites (higher is better). The error bars are 90% confidence intervals computed by the bootstrap. At left are the PRESS rankings from the leave-one-year-out cross validation (a), at right are the PRESS rankings from the leave-one-out cross validation (b).](figure/press-barchart.png) 
    
    
\begin{table}
    \centering
    \begin{tabular}{rccccccc}
    







