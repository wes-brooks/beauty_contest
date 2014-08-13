require(ggplot2)
require(reshape2)
require(dplyr)

#Load the raw results of the beauty contest:
load("beauty_contest.RData")
load("variable_supplement.RData")
source("R/ROC.r")

#S is the number of bootstrap samples
S = 11

#Nicer names for the paper
pretty.methods = list(
    'gbm'='GBM-OOB',
    'gbmcv'='GBM-CV',
    'pls'='PLS',
    'spls'='SPLS',
    'spls-select'='SPLS (s)',
    'adapt'='AL',
    'adapt-select'='AL (s)',
    'adalasso-weighted'='AL (w,b)',
    'adalasso-weighted-select'='AL (w,b,s)',
    'adalasso-unweighted'='AL (l)',
    'adalasso-unweighted-select'='AL (b,s)',
    'galm'='GA',
    'galogistic-weighted'='GA (w,b)',
    'galogistic-unweighted'='GA (b)'
)

lasso.and.gbm = list(
    'adapt'='AL',
    'gbm'='GBM-OOB'
)

pretty.sites = list(
    hika='Hika',
    point='Point',
    redarrow='Red Arrow',
    neshotah='Neshotah',
    maslowski='Maslowski',
    kreher='Kreher',
    thompson='Thompson'
)

#This is a formatting function to put newlines in the column labels
pretty.cols <- function(x,...){
    x = gsub('.', '-', x, fixed=TRUE)
    res = sapply(x, function(z) pretty.methods[[z]])
    res = gsub('[ ]', ' \\\\\\\\ ', res, perl=TRUE)
    res = gsub('-', '- \\\\\\\\ ', res, perl=TRUE)
    res = paste("\\begin{tabular}{c}", res, "\\end{tabular}", sep="")
    res
}

#This is a formatting function to put newlines in the column labels
pretty.rows <- function(x,...){
    x = gsub('.', '-', x, fixed=TRUE)
    res = sapply(x, function(z) pretty.methods[[z]])
    res
}

#This is a formatting function to put newlines in the plot labels
pretty <- function(x) {
    x = gsub('.', '-', x, fixed=TRUE)
    n = sapply(x, function(z) pretty.methods[[z]]) %>% as.vector
    n
}
