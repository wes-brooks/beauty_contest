cv_folds = 5
first = TRUE

settings = beaches[[beach]]
regulatory = settings[['threshold']]
target = settings[['target']]

#Read the beach's data.
datafile = settings[["file"]]
data = read.csv(datafile)

#Partition the data into cross-validation folds.
folds = Partition(data, folds='years')
nfolds = length(unique(folds))

if ('remove' %in% names(settings)) {
	data = data[,!(names(data) %in% settings[['remove']])]
}

#Apply the specified transforms to the raw data.
for (t in settings[['transforms']]) {
	data[,t] = settings[['transforms']][[t]](data[,t])
}

rocframe = matrix(NA, nrow=0, ncol=4)
predperf = matrix(NA, nrow=0, ncol=4)

f = process
traindata = data[folds!=f,]
valdata = data[folds==f,]

innerfolds = Partition(traindata, folds=cv_folds)

job_output = list()

#Run the modeling routine
if (first) {
	#sink(paste(output, paste(prefix, beach, method, "annual", "out", sep="."), sep=''))            
    #if (!is.null(seed)) {cat(paste("# Seed = ", seed, "\n", sep=''))}
	#cat(paste("# Site = ", beach, "\n", sep=''))
	#cat(paste("# Method = ", method, "\n", sep=''))
	#sink()

    if (!is.null(seed)) {job_output[[length(job_output)+1]] = paste("# Seed = ", seed, "\n", sep='')}
    job_output[[length(job_output)+1]] = paste("# Site = ", beach, "\n", sep='')
    job_output[[length(job_output)+1]] = paste("# Method = ", method, "\n", sep='')
    first = FALSE
}

#Run this modeling method against the beach data.
valpar = c(params[[method]],
	list(
		data=traindata,
		target=settings[['target']],
		method=method,
		folds=innerfolds,
		regulatory_threshold=settings[['threshold']]
	)
)
result = do.call(Validate, valpar)
model = result[[2]]
results = result[[1]]

#Set the threshold for predicting the reserved test set
indx1 = which(sapply(1:length(results[['tpos']]), function(i) {results[['tpos']][i] >= results[['fneg']][i]}))
indx2 = which(sapply(1:length(results[['tpos']]), function(i) {results[['tpos']][i] >= results[['fpos']][i]}))
indx = which(sapply(1:length(results[['tpos']]), function(k) {(k %in% indx1) && (k %in% indx2)})) 
if (length(indx)==0) {
	if (length(indx1)==0) {
		specificity = max(results[['threshold']] <= 0.8)
	} else {
		specificity = max(results[['threshold']][indx1])
	}
} else {
	specificity = min(results[['threshold']][indx])
}

model <- model[['Threshold']](model, specificity)
t = model[['threshold']]

#sink(paste(output, paste(prefix, beach, method, "annual", "out", sep="."), sep=''))            
#cat(paste("# threshold = ", t, "\n", sep=''))
#sink()
job_output[[length(job_output)+1]] = paste("# threshold = ", t, "\n", sep='')

predictions = model[['Predict']](self=model, data=valdata)
validation_actual = valdata[,target]        

fitted = model[['fitted']]
actual = model[['actual']]

#Sensitivity and specificity are over the training data:
nonexceedances = fitted[actual <= regulatory]
exceedances = fitted[actual > regulatory]
	
if (length(nonexceedances) == 0) {                
	threshold = rep(1, length(predictions))
} else {                
	cc = ecdf(nonexceedances)
	threshold = cc(predictions)
}

foldresult = as.data.frame(list(predicted=predictions, actual=validation_actual, threshold=threshold, fold=rep(f, length(threshold))))
#rocframe = rbind(rocframe, foldresult)

predperf = rbind(predperf, as.data.frame(list(
	tpos = length(which(predictions > t & validation_actual > regulatory)),
	tneg = length(which(predictions <= t & validation_actual <= regulatory)),
	fpos = length(which(predictions > t & validation_actual <= regulatory)),
	fneg = length(which(predictions <= t & validation_actual > regulatory))
)))

##For making the ROC curve:
#tpos = tneg = fpos = fneg = rep(NA, length(rocframe$threshold))
#for (k in 1:nrow(rocframe)) {
#    t = rocframe$threshold[k]
#    tpos[k] = length(which(rocframe$threshold > t & rocframe$actual > regulatory))
#    tneg[k] = length(which(rocframe$threshold <= t & rocframe$actual <= regulatory))
#    fpos[k] = length(which(rocframe$threshold > t & rocframe$actual <= regulatory))
#    fneg[k] = length(which(rocframe$threshold <= t & rocframe$actual > regulatory))
#}
#
#rocframe = cbind(rocframe, tpos, tneg, fpos, fneg)
#rocframe = rocframe[order(rocframe$threshold),]



#Open a file to which we will append the output.
#sink(paste(output, paste(prefix, beach, method, "annual", "out", sep='.'), sep=""), append=TRUE)

#cat("# rocframe: \n")
#print(foldresult)
#cat("# predperf: \n")
#print(predperf)

#Clean up and move on.
#warnings()
#sink()

job_output[[length(job_output)+1]] = "# rocframe: \n"
job_output[[length(job_output)+1]] = foldresult
job_output[[length(job_output)+1]] = "# predperf: \n"
job_output[[length(job_output)+1]] = predperf

#Clean up and move on.
job_output[[length(job_output)+1]] = warnings()
sapply(job_output, print)

sink(paste(beach, method, process, "out", sep="."))
sapply(job_output, print)
sink()