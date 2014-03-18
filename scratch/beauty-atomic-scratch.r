source("R/import-packages.r")
source("R/settings.r")
source('R/utils.r')

type='loo'
cluster = NA
beach = 'redarrow'
method = 'pls'
process = 93

result = "placeholder"
output = ""
seed = 1

prefix = paste("~/scratch/beautyrun", process, sep=".")

source("R/loo-atomic.r")


