#Set ourselves up to import the packages:
dir.create("rlibs")
Sys.setenv(R_LIBS="rlibs")
.libPaths(new="rlibs")

sink("result.txt", append=TRUE)

require(Matrix)
require(lattice)

#These are the modeling modules:
source('R/gbm.r')
source('R/pls.r')
source('R/galm.r')
source('R/galogistic.r')
source('R/adapt.r')
source('R/adalasso.r')
source('R/spls.r')
sink()
