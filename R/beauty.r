require(devtools)
source('gbm.r')
source('pls.r')
source('galm.r')
source('galogistic.r')
source('adapt.r')
source('adalasso.r')
source('spls.r')

source('settings.r')
source('utils.r')

#We call this script with command line arguments from Condor
if (length(commandArgs()) > 1) {
    seeds = read.table("../seeds.txt")
    
    cluster = as.numeric(commandArgs(TRUE)[1])
    process = as.numeric(commandArgs(TRUE)[2]) + 1
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
    
} else {
    cluster = "na"
    process = "na"
    locs = names(beaches)
    tasks = names(methods)
    seed = 0
}

cv_folds = 5
result = "placeholder"
output = "../output/"

#Set the timestamp we'll use to identify the output files.
prefix = paste(cluster, process, sep=".")


     