sink("result.txt")
cat(paste('entry', "\n", sep=''))
sink()

source("R/import-packages.r")

#Import location and modeling settings:
source('R/settings.r')

#Import some necessary functions:
source('R/utils.r')

sink("result.txt", append=TRUE)
cat(paste('going to seeds', "\n", sep=''))
sink()

#Load the process ID from the jobid.txt file
seeds = read.table("seeds.txt")

args = scan('params.txt', 'character')
args = strsplit(args, '\\n', fixed=TRUE)[[1]]

type = args[1]
cluster = args[2]
beach = args[3]
method = args[4]
process = as.numeric(args[5])

seed = (1000 * seeds[process,]) %/% 1
    
sink("result.txt", append=TRUE)
cat(paste('type: ', type, "\n", sep=''))
cat(paste('location: ', beach, "\n", sep=''))
cat(paste('method: ', method, "\n", sep=''))
cat(paste('process: ', process, "\n", sep=''))
sink()
    
result = "placeholder"
output = ""

#Set the timestamp we'll use to identify the output files.
prefix = paste(cluster, process, sep=".")

sink("result.txt", append=TRUE)
cat(paste("output prefix: ", prefix, "\n", sep=''))
sink()

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


file.rename(from="result.txt", to=paste("result-", type, "-", process, ".txt", sep=""))
