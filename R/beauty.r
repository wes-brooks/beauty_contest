sink("result.txt")
cat(paste('entry', "\n", sep=''))
sink()

#Set ourselves up to import the packages:
r = getOption("repos")
r["CRAN"] = "http://cran.wustl.edu"
options(repos = r)
rm(r)
dir.create("rlibs")
Sys.setenv(R_LIBS="rlibs")
#.libPaths(new="rlibs")
install.packages("gbm")
install.packages("pls")
install.packages("lars")
install.packages("glmnet")
install.packages("spls")
require(devtools)

sink("result.txt", append=TRUE)
cat(paste('installations complete', "\n", sep=''))
sink()

sink("result.txt", append=TRUE)
#These are the modeling modules:
source('gbm.r')
cat("loaded gbm\n")
source('pls.r')
cat("loaded pls\n")
source('galm.r')
cat("loaded galm\n")
source('galogistic.r')
cat("loaded galogistic\n")
source('adapt.r')
cat("loaded adapt\n")
source('adalasso.r')
cat("loaded adalasso\n")
source('spls.r')
cat("loaded spls\n")
sink()

sink("result.txt", append=TRUE)
cat(paste('going to settings', "\n", sep=''))
sink()

#Import location and modeling settings:
source('settings.r')

sink("result.txt", append=TRUE)
cat(paste('going to utils', "\n", sep=''))
sink()

#Import some necessary functions:
source('utils.r')

sink("result.txt", append=TRUE)
cat(paste('going to seeds', "\n", sep=''))
sink()

#Load the process ID from the jobid.txt file
seeds = read.table("seeds.txt")

sink("result.txt", append=TRUE)
cat(paste('got seeds', "\n", sep=''))
sink()

args = scan('jobid.txt', 'character')
args = strsplit(args, '\\n', fixed=TRUE)[[1]]

sink("result.txt", append=TRUE)
cat(paste('jobid:', args[2], "\n", sep=''))
sink()

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
    
sink("result.txt", append=TRUE)
cat(paste('location: ', paste(locs, collapse=","), "\n", sep=''))
cat(paste('method: ', paste(tasks, collapse=","), "\n", sep=''))
sink()
    
cv_folds = 5
result = "placeholder"
output = ""

#Set the timestamp we'll use to identify the output files.
prefix = paste(cluster, process, sep=".")

sink("result.txt", append=TRUE)
cat(paste(prefix, "\n", sep=''))
sink()

source("loo.r")
source('annual.r')
