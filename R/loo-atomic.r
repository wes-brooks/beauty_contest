cv_folds = 'loo'
first = TRUE

#Read the beach's data.
settings = beaches[[beach]]
datafile = settings[["file"]]
data = read.csv(datafile)

if ('remove' %in% names(settings)) {
	data = data[,!(names(data) %in% settings[['remove']])]
}

#Apply the specified transforms to the raw data.
for (t in settings[['transforms']]) {
	data[,t] = settings[['transforms']][[t]](data[,t])
}

#Partition the data into cross-validation folds.
folds = Partition(data, cv_folds)

#Run the modeling routine
if (first) {
	sink(paste(output, paste(prefix, beach, method, "out", sep="."), sep=''))            
	if (!is.null(seed)) {cat(paste("# Seed = ", seed, "\n", sep=''))}
	cat(paste("# Site = ", beach, "\n", sep=''))
	cat(paste("# Method = ", method, "\n", sep=''))
	sink()
	first = FALSE
}

#Run this modeling method against the beach data.
valpar = c(params[[method]],
	list(
		data=data,
		target=settings[['target']],
		method=method,
		fold=process,
		folds=folds,
		regulatory_threshold=settings[['threshold']]
	)
)
result = do.call(ValidateAtomic, valpar)

#Open a file to which we will append the output.
sink(paste(output, paste(prefix, beach, method, "out", sep='.'), sep=""), append=TRUE)
cat("# predicted: \n")
cat(paste(result[['predicted']], "\n", sep=""))
cat("# actual: \n")
cat(paste(result[['actual']], "\n", sep=""))
cat("# threshold: \n")
cat(paste(result[['threshold']], "\n", sep=""))
cat("# fold: \n")
cat(paste(result[['fold']], "\n", sep=""))
cat("# vars: \n")
cat(paste(paste(result[['vars']], collapse=", "), "\n", sep=""))

#Clean up and move on.
warnings()
sink()