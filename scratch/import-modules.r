#Set ourselves up to import the packages:
r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)
dir.create("rlibs")
Sys.setenv(R_LIBS="rlibs")
.libPaths(new="rlibs")

sink("result.txt", append=TRUE)
#These are the modeling modules:
source('R/gbm.r')
source('R/pls.r')
source('R/galm.r')
source('R/galogistic.r')
source('R/adapt.r')
source('R/adalasso.r')
source('R/spls.r')
sink()
