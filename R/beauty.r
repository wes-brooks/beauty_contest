#Set ourselves up to import the packages:
r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)
dir.create("rlibs")
Sys.setenv(R_LIBS="rlibs")
install.packages("devtools")
require(devtools)

#These are the modeling modules:
source('R/gbm.r')
source('R/pls.r')
source('R/galm.r')
source('R/galogistic.r')
source('R/adapt.r')
source('R/adalasso.r')
source('R/spls.r')

#Import location and modeling settings:
source('R/settings.r')

#Import some necessary functions:
source('R/utils.r')

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

source("R/annual.r")
