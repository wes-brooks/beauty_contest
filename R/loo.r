for (beach in locs) {
    first = Map(function(x) {return(TRUE)}, tasks)

    #Read the beach's data.
    datafile = beaches[[beach]][["file"]]
    
    data = read.csv(datafile)
    if ('remove' %in% names(beaches[[beach]])) {
        data = data[,!(names(data) %in% beaches[[beach]][['remove']])]
	}
	
    #Apply the specified transforms to the raw data.
    for (t in beaches[[beach]][['transforms']]) {
        data[,t] = beaches[[beach]][['transforms']][[t]](data[,t])
	}
    
    #Partition the data into cross-validation folds.
    folds = Partition(data, cv_folds)
    
	#Run the modeling routines.
	for (method in tasks) {
		if (first[[method]]) {
			sink(paste(output, paste(prefix, beach, method, "out", sep="."), sep=''))            
			if (!is.null(seed)) {cat(paste("# Seed = ", seed, "\n", sep=''))}
			cat(paste("# Site = ", beach, "\n", sep=''))
			cat(paste("# Method = ", method, "\n", sep=''))
			sink()
			first[[method]] = FALSE
		}
	
		#Run this modeling method against the beach data.
		valpar = c(params[[method]],
			list(
				data=data,
				target=beaches[[beach]][['target']],
				method=method,
				folds=folds,
				regulatory_threshold=beaches[[beach]][['threshold']]
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
		indx = which(results[['threshold']] == specificity)[1]
		
		#Predict exceedances on the test set and add them to the results structure.
		model <- model[['Threshold']](model, specificity)		
		
		#Open a file to which we will append the output.
        sink(paste(output, paste(prefix, beach, method, "out", sep='.'), sep=""), append=TRUE)        
        cat(paste("# Area under ROC curve = ", ROC(results), "\n", sep=''))
        cat(paste("# aggregate.tpos = ", results[['tpos']][indx], "\n", sep=""))
        cat(paste("# aggregate.tneg = ", results[['tneg']][indx], "\n", sep=""))
        cat(paste("# aggregate.fpos = ", results[['fpos']][indx], "\n", sep=""))
        cat(paste("# aggregate.fneg = ", results[['fneg']][indx], "\n", sep=""))
        cat(paste("# variables: ", paste(model[['vars']], collapse=', '), "\n", sep=""))
        cat(paste("# thresholding specificity: ", model[['specificity']], "\n", sep=""))
        cat(paste("# decision threshold: ", model[['threshold']], "\n", sep=""))
		cat(paste("# full results: \n", results, "\n", sep=""))
        
        #Clean up and move on.
        warnings()
        sink()
	}
}