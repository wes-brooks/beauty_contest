source("R/import-packages.r")
source("R/settings.r")
source('R/utils.r')

type='loo'
cluster = NA
beach = 'neshotah'
method = 'gbmcv'
process = 1

result = "placeholder"
output = ""
seed = 1

prefix = paste("~/scratch/out", cluster, process, sep=".")

source("R/loo-atomic.r")


