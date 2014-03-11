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
	sink(paste(output, paste(prefix, beach, method, "final", "out", sep="."), sep=''))            
	if (!is.null(seed)) {cat(paste("# Seed = ", seed, "\n", sep=''))}
	cat(paste("# Site = ", beach, "\n", sep=''))
	cat(paste("# Method = ", method, "\n", sep=''))
	sink()
	first = FALSE
}

module = params[['env']]
model <- module$Model

#Run this modeling method against the beach data.
params = c(
    list(
        self = model,
        data=data,
        target=settings[['target']],
        fold=process,
        folds=folds,
        regulatory_threshold=settings[['threshold']]
    ),
    params[[method]]	
)
model <- do.call(model[['Create']], params)

fitted = model[['fitted']]
actual = data[[target]]
result = cbind(actual=actual, fitted=fitted)


sink(paste(output, paste(prefix, beach, method, "final", "out", sep='.'), sep=""), append=TRUE)  
cat("# vars:\n")
print(vars)
cat("# actual, fitted:\n")
print(result)

#Clean up and move on.
warnings()
sink()
