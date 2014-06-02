source("scratch/import-modules.r")
source("R/settings.r")
source('R/utils.r')

type='loo'
cluster = NA
beach = 'thompson'
method = 'adalasso-unweighted-select'
processes = c(115)

result = "placeholder"
output = ""
seed = 10

for (process in processes) {
  prefix = paste("~/scratch/beautyrun", process, sep=".")
  cat(paste("process: ", process, "\n", sep=""))
  source("R/loo-atomic.r")
}


