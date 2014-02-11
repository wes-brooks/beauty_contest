#Set ourselves up to import the packages:
r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)
#dir.create("C:\\Users\\wrbrooks\\scratch\\rlibs")
#Sys.setenv(R_LIBS="C:\\Users\\wrbrooks\\scratch\\rlibs")
#.libPaths(new="C:\\Users\\wrbrooks\\scratch\\rlibs")
dir.create("~/scratch/rlibs")
Sys.setenv(R_LIBS="~/scratch/rlibs")
.libPaths(new="~/scratch/rlibs")

install.packages("gbm")
install.packages("pls")
install.packages("lars")
install.packages("glmnet")
install.packages("spls")

setwd("~/git/beauty_contest")
install.packages("R-libs/adalasso", repos=NULL, type='source')
install.packages("R-libs/adalars", repos=NULL, type='source')
install.packages("R-libs/galm", repos=NULL, type='source')
install.packages("R-libs/galogistic", repos=NULL, type='source')
install.packages("R-libs/spls.wrap", repos=NULL, type='source')

source('R/gbm.r')
source('R/pls.r')
source('R/galm.r')
source('R/galogistic.r')
source('R/adapt.r')
source('R/adalasso.r')
source('R/spls.r')

source("R/settings.r")
source('R/utils.r')

type='loo'
cluster = NA
beach = 'redarrow'
method = 'adapt'
process = 1

result = "placeholder"
output = ""
seed = 1

prefix = paste("~/scratch/out", cluster, process, sep=".")

source("R/loo-atomic.r")


