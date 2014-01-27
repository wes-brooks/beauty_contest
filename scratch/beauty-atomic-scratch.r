#Set ourselves up to import the packages:
r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)
dir.create("C:\\Users\\wrbrooks\\scratch\\rlibs")
Sys.setenv(R_LIBS="C:\\Users\\wrbrooks\\scratch\\rlibs")
.libPaths(new="C:\\Users\\wrbrooks\\scratch\\rlibs")

install.packages("gbm")
install.packages("pls")
install.packages("lars")
install.packages("glmnet")
install.packages("spls")

install.packages("C:\\Users\\wrbrooks\\git\\beauty_contest\\R-libs\\adalasso", repos=NULL, type='source')
install.packages("C:\\Users\\wrbrooks\\git\\beauty_contest\\R-libs\\adalars", repos=NULL, type='source')
install.packages("C:\\Users\\wrbrooks\\git\\beauty_contest\\R-libs\\galm", repos=NULL, type='source')
install.packages("C:\\Users\\wrbrooks\\git\\beauty_contest\\R-libs\\galogistic", repos=NULL, type='source')
install.packages("C:\\Users\\wrbrooks\\git\\beauty_contest\\R-libs\\spls.wrap", repos=NULL, type='source')

source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\gbm.r')
source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\pls.r')
source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\galm.r')
source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\galogistic.r')
source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\adapt.r')
source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\adalasso.r')
source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\spls.r')

source("C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\settings.r")
source('C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\utils.r')

type='loo'
cluster = NA
beach = 'kreher'
method = 'galogistic-unweighted'
process = 1

result = "placeholder"
output = ""
seed = 1

prefix = paste("C:\\Users\\wrbrooks\\scratch\\out", cluster, process, sep=".")

setwd("C:\\Users\\wrbrooks\\git\\beauty_contest")
source("C:\\Users\\wrbrooks\\git\\beauty_contest\\R\\loo-atomic.r")





v = rnorm(100)
w = rnorm(100)
x = rnorm(100)
y = rnorm(100)
z = rnorm(100)

eta = 5*x + 2*w
p = exp(eta) / (1+exp(eta))
b = rbinom(100, size=1, p=p)
d = data.frame(v,w,x,y,z,b)

galogistic(b~v+w+x+y+z, data=d, family='binomial', mutateRate=0.05, ZOR=10, generations=10)

