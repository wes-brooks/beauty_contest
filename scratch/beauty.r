#sink("result.txt")
cat(paste('entry', "\n", sep=''))
#sink()

#Set ourselves up to import the packages:
r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)
dir.create("~/scratch/rlibs")
Sys.setenv(R_LIBS="~/scratch/rlibs")
.libPaths(new="~/scratch/rlibs")
#install.packages("gbm")
#install.packages("pls")
#install.packages("lars")
#install.packages("glmnet")
#install.packages("spls")

install.packages("R-libs/adalasso", repos=NULL, type='source')
install.packages("R-libs/adalars", repos=NULL, type='source')
install.packages("R-libs/galm", repos=NULL, type='source')
install.packages("R-libs/galogistic", repos=NULL, type='source')
install.packages("R-libs/spls.wrap", repos=NULL, type='source')

#sink("result.txt", append=TRUE)
cat(paste('installations complete', "\n", sep=''))
#sink()

#sink("result.txt", append=TRUE)
#These are the modeling modules:
source('R/gbm.r')
cat("loaded gbm\n")
source('R/pls.r')
cat("loaded pls\n")
source('R/galm.r')
cat("loaded galm\n")
source('R/galogistic.r')
cat("loaded galogistic\n")
source('R/adapt.r')
cat("loaded adapt\n")
source('R/adalasso.r')
cat("loaded adalasso\n")
source('R/spls.r')
cat("loaded spls\n")
#sink()

#sink("result.txt", append=TRUE)
cat(paste('going to settings', "\n", sep=''))
#sink()

#Import location and modeling settings:
source('R/settings.r')

#sink("result.txt", append=TRUE)
cat(paste('going to utils', "\n", sep=''))
#sink()

#Import some necessary functions:
source('R/utils.r')

#sink("result.txt", append=TRUE)
cat(paste('going to seeds', "\n", sep=''))
#sink()

#Load the process ID from the jobid.txt file
seeds = read.table("seeds.txt")

#sink("result.txt", append=TRUE)
cat(paste('got seeds', "\n", sep=''))
#sink()

args = scan('scratch/jobid.txt', 'character')
args = strsplit(args, '\\n', fixed=TRUE)[[1]]

#sink("result.txt", append=TRUE)
cat(paste('jobid:', args[2], "\n", sep=''))
#sink()

cluster = args[1]
process = as.numeric(args[2]) - 1
sites = names(beaches)

s = length(sites)
m = length(names(params))
d = c(process %/% s, process %% s)
mm = c(d[1] %/% m, d[1] %% m)

meth = mm[2] + 1
site = d[2] + 1

locs = sites[site]
tasks = names(params)[meth]
seed = (1000 * seeds[s*mm[1]+site,]) %/% 1
    
#sink("result.txt", append=TRUE)
cat(paste('location: ', paste(locs, collapse=","), "\n", sep=''))
cat(paste('method: ', paste(tasks, collapse=","), "\n", sep=''))
#sink()
    
result = "placeholder"
output = ""

#Set the timestamp we'll use to identify the output files.
prefix = paste('scratch/', paste(cluster, process, sep="."), sep='')

#sink("result.txt", append=TRUE)
cat(paste(prefix, "\n", sep=''))
#sink()

source("R/loo.r")
source('R/annual.r')
