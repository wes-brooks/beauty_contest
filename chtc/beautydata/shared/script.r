sink("output.dat")

r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)

dir.create("rlibs")
Sys.setenv(R_LIBS="rlibs")

install.packages("devtools")
require(devtools)
cat("installed, loaded devtools\n")

install.packages("lars")
require(lars)
cat("installed, loaded lars\n")

install.packages("pls")
require(pls)
cat("installed, loaded pls\n")

install.packages("glmnet")
require(glmnet)
cat("installed, loaded glmnet\n")

install.packages("gbm")
require(gbm)
cat("installed, loaded gbm\n")

install.packages("spls")
require(spls)
cat("installed, loaded spls\n")

install("R-libs/spls.wrap")
require(spls.wrap)
cat("installed, loaded spls.wrap\n")

cat("done\n")
sink()
