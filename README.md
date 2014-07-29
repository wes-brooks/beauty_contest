# Comparing regression methods for modeling the bacterial concentration in beach water


## How to run the contest:
The easiest way to run a single method for a single observation at a single site is to use the script `scratch/beauty-atomic-scratch.r`, modifying that script's first section to run the contest on the appropriate data. The main part of the contest was run on a massively parallel environment via [Condor](http://research.cs.wisc.edu/htcondor/). That mani run was sent out to the compute nodes via the shell script `chtc/boot.sh`, which calls `chtc/Makefile` to do the work of sending out jobs.

## What is the contest?
We wanted to see which regression technique performs best for modeling the concentration of *E. coli* in beach water. Fourteen settings were tested (using seven modules - several modules had optional settings that were counted as new settings) at seven sites in Wisconsin. Eash site was modeled with each setting and the performance was compared.

## Modules to compare:
These are the modules for the contest:

 - `gbm` Gradient moosting machine
 - `pls` Partial least squares
 - `adapt` Adaptive lasso (for gaussian response)
 - `adalasso` Adaptive lasso (for logistic regression)
 - `galm` Genetic algorithm for gaussian response
 - `galogistic` Genetic algorithm for logistic regression
 - `spls` Sparse partial least squares (combines lasso and PLS)
 
## About the data
Data for the contest were collected either manually or automatically. Automatic collection was the majority, and came from the [USGS'](http://usgs.gov) [EnDDaT](http://cida.usgs.gov/enddat/) and [GeoDataPortal](http://cida.usgs.gov/gdp/) tools. Manual collection was driven by the [EPA's](http://epa.gov) [Beach Sanitary Surveys](http://water.epa.gov/type/oceb/beaches/sanitarysurvey_index.cfm).

## How performance was measured
Our models are used to drive a decision of whether or not to post a warning at the beach. Therefore, we are ultimately interested in which method most accurately classified its predictions as exceedances or nonexceedances. For the linear regression techniques, accurately predicting the actual concentration was important, too. In the end, there were three performance measures:

 - Area under the ROC curve (AUROC - measures how well a model sorted exceedances from nonexceedances
 - Predictive error sum of squares (PRESS) - measures the total squared error of the model's predictions
 - Classification of responses - counts of the true/false positives and true/false negatives from the model's predictions
 
The classification of responses is like AUROC, but for a specific choice of threshold rather than averaged over the possible thresholds.
 
## How the contest works
The scripts to do the work of the contest are in the `R/` directory. Secifically, `R/beauty-atomic` and `R/annual-atomic` manage the dirty work of fitting models and making predictions from them. That dirty work is actually done in the modules, which are R scripts under the names given in the list above. There is a common interface to the modules: the required methods are `Create` and `Predict`.