source("R/import-packages.r")
source("R/settings.r")
source('R/utils.r')

type='loo'
cluster = NA
beach = 'point'
method = 'spls'
processes = c(139, 149, 156, 174, 175, 177, 183, 185, 188)

result = "placeholder"
output = ""
seed = 1

for (process in processes) {
  prefix = paste("~/scratch/beautyrun", process, sep=".")
  cat(paste("process: ", process, "\n", sep=""))
  source("R/loo-atomic.r")
}


