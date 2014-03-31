source("scratch/import-modules.r")
source("R/settings.r")
source('R/utils.r')

type='annual'
cluster = NA
beach = 'point'
method = 'spls'
processes = c(1)

result = "placeholder"
output = ""
seed = 1

for (process in processes) {
  prefix = paste("~/scratch/beautyrun", process, sep=".")
  cat(paste("process: ", process, "\n", sep=""))
  
  #Use the process number to determine whether we'll run loo or annual, and with which fold
  if (type=='loo') {
      source("R/loo-atomic.r")
  }
  
  if (type=='annual') {
      source('R/annual-atomic.r')
  }
  
  if (type=='final') {
      source('R/final-atomic.r')
  }
}


