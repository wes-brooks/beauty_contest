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
.libPaths(new="rlibs")
install.packages("gbm")
install.packages("pls")
install.packages("lars")
install.packages("glmnet")
install.packages("spls")

install.packages("R-libs/adalasso", repos=NULL, type='source')
install.packages("R-libs/adalars", repos=NULL, type='source')
install.packages("R-libs/galm", repos=NULL, type='source')
install.packages("R-libs/galogistic", repos=NULL, type='source')
install.packages("R-libs/spls.wrap", repos=NULL, type='source')

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

args = scan('params.txt', 'character')
args = strsplit(args, '\\n', fixed=TRUE)[[1]]

sink("result.txt", append=TRUE)
cat(paste('jobid:', args[4], "\n", sep=''))
sink()

type = args[1]
cluster = args[2]
beach = args[3]
method = args[4]
process = as.numeric(args[5])

seed = (1000 * seeds[process,]) %/% 1
    
sink("result.txt", append=TRUE)
cat(paste('location: ', beach, "\n", sep=''))
cat(paste('method: ', method, "\n", sep=''))
sink()
    
result = "placeholder"
output = ""

#Set the timestamp we'll use to identify the output files.
prefix = paste(cluster, process, sep=".")

sink("result.txt", append=TRUE)
cat(paste(prefix, "\n", sep=''))
sink()

#Use the process number to determine whether we'll run loo or annual, and with which fold

if (type=='loo') {
	source("loo-atomic.r")
}

if (type=='annual') {
	source('annual-atomic.r')
}
