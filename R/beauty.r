#Set ourselves up to import the packages:
r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)
dir.create("rlibs")
Sys.setenv(R_LIBS="rlibs")
install.packages("devtools")
install.packages("gbm")
install.packages("pls")
install.packages("lars")
install.packages("glmnet")
install.packages("spls")
require(devtools)

#These are the modeling modules:
source('gbm.r')
source('pls.r')
source('galm.r')
source('galogistic.r')
source('adapt.r')
source('adalasso.r')
source('spls.r')

#Import location and modeling settings:
source('settings.r')

#Import some necessary functions:
source('utils.r')

#Load the process ID from the jobid.txt file
seeds = read.table("seeds.txt")

args = scan('jobid.txt', 'character')
cluster = args[1]
process = as.numeric(args[2])
sites = names(beaches)

s = length(sites)
m = length(names(methods))
d = c(process %/% s, process %% s)
mm = c(d[1] %/% m, d[1] %% m)

meth = mm[2] + 1
site = d[2] + 1

locs = sites[site]
tasks = names(methods)[meth]
seed = (1000 * seeds[s*mm[1]+site,]) %/% 1
    
    
    
cv_folds = 5
result = "placeholder"
output = ""

#Set the timestamp we'll use to identify the output files.
prefix = paste(cluster, process, sep=".")

cat(paste(prefix, "\n", sep=''))

source("loo.r")
