require(Matrix)
require(lattice)

#Sys.setenv(R_LIBS="rlibs")
#.libPaths(new="rlibs")
#source("R/galogistic.r")
source("R/gbm.r")
#source("R/galm.r")

#source("scratch/import-modules.r")
source("R/settings.r")
source('R/utils.r')




type='annual'
cluster = NA
beach = 'thompson'
method = 'gbm'
processes = c(2)

result = "placeholder"
output = ""
seed = 10

for (process in processes) {
  prefix = paste("~/Dropbox/beauty/beautyrun", process, sep=".")
  prefix = paste("C:\\Users\\wrbrooks/Dropbox/beauty/beautyrun", process, sep=".")
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


