source("R/import-packages.r")
source("R/settings.r")
source('R/utils.r')

type='loo'
cluster = NA
beach = 'point'
method = 'spls'
processes = c(189

result = "placeholder"
output = ""
seed = 1

prefix = paste("~/scratch/beautyrun", process, sep=".")


for (process in processes) {
  source("R/loo-atomic.r")
}

