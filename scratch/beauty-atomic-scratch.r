source("R/import-packages.r")
source("R/settings.r")
source('R/utils.r')

type='loo'
cluster = NA
beach = 'thompson'
method = 'adapt'
process = 49

result = "placeholder"
output = ""
seed = 1

prefix = paste("~/scratch/beautyrun", process, sep=".")

source("R/loo-atomic.r")


