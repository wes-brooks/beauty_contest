cv_folds = 'loo'
source('ROC.r')

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
#		thresholding = SpecificityChart(results)
		
		#Set the threshold for predicting the reserved test set
		indx = which(sapply(1:length(results[['tpos']]), function(i) {results[['tpos']][i] >= results[['fneg']][i]}))
		if (length(indx)==0) {
			specificity = max(results[['threshold']] <= 0.8)
		} else {specificity = max(results[['threshold']][indx])}
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
        
        #Clean up and move on.
        #OutputROC(ROC[method])
        sink()



		#predictions = model[['Predict']](self=model, data=test_set)
#		truth = test_set[,beaches[[beach]][['target']]]
#		
#		#These will be used to calculate the area under the ROC curve:
#		rank = order(truth)
#		ROC[[method]][['validate']][[length(ROC[[method]][['validate']]) + 1L]] = truth
#		ROC[[method]][['predicted']][[length(ROC[[method]][['predicted']]) + 1L]] = predictions
#		ROC[[method]][['train']][[length(ROC[[method]][['train']]) + 1L]] = model[['actual']]
#		ROC[[method]][['fitted']][[length(ROC[[method]][['fitted']]) + 1L]] = model[['fitted']]
#		
#		#Calculate the predictive perfomance for the model
#		tpos = sum(sapply(1:length(predictions), function(i) {predictions[i] > model[['threshold']] && truth[i] > beaches[[beach]][['threshold']]}))
#		tneg = sum(sapply(1:length(predictions), function(i) {predictions[i] <= model[['threshold']] && truth[i] <= beaches[[beach]][['threshold']]}))
#		fpos = sum(sapply(1:length(predictions), function(i) {predictions[i] > model[['threshold']] && truth[i] <= beaches[[beach]][['threshold']]}))
#		fneg = sum(sapply(1:length(predictions), function(i) {predictions[i] <= model[['threshold']] && truth[i] > beaches[[beach]][['threshold']]}))
#		
#		#Add predictive performance stats to the aggregate.
#		validation[[method]][['tpos']] = validation[[method]][['tpos']] + tpos
#		validation[[method]][['tneg']] = validation[[method]][['tneg']] + tneg
#		validation[[method]][['fpos']] = validation[[method]][['fpos']] + fpos
#		validation[[method]][['fneg']] = validation[[method]][['fneg']] + fneg
#	
#		#Store the performance information.
#		#Open a file to which we will append the output.
#		sink(paste(output, paste(prefix, beach, method, "out", sep='.'), sep=''), append=(f!=1))
#		cat(paste("# fold = ", f, "\n", sep=""))
#		cat(paste("# threshold = ", model[['threshold']], "\n", sep=""))
#		cat(paste("# requested specificity = ", specificity, "\n", sep=""))
#		cat(paste("# actual training-set specificity = ", model[['specificity']], "\n", sep=""))
#		cat(paste("# tpos = ", tpos, "\n", sep=""))
#		cat(paste("# tneg = ", tneg, "\n", sep=""))
#		cat(paste("# fpos = ", fpos, "\n", sep=""))
#		cat(paste("# fneg = ", fneg, "\n", sep=""))                
#		cat("# raw predictions:\n")
#		cat(predictions)
#		cat("\n# truth:\n")
#		cat(truth)
#		cat("\n# fitted:\n")
#		cat(model[['fitted']])
#		cat("\n# actual:\n")
#		cat(model[['actual']])
#		cat("\n")
#		sink()
    }
      
#    for (m in tasks) {
#        #Store the performance information.
#        #First, create a model for variable selection:
#        
#        #Run this modeling method against the beach data.
#        valpar = c(params[[m]],
#            list(data=data,
#                target=beaches[[beach]][['target']],
#                method=method,
#                folds=folds,
#                regulatory_threshold=beaches[[beach]][['threshold']]
#            )
#        )
#        result = do.call(Validate, valpar)
#        model = result[[2]]
#        results = result[[1]]
#        thresholding = SpecificityChart(results)
#        
#        #Set the threshold for predicting the reserved test set
#        indx = which(sapply(1:length(thresholding[['tpos']]), function(i) {thresholding[['tpos']][i] >= thresholding[['fpos']][i]}))
#        if (length(indx)==0) {specificity = 0.9}
#        else {specificity = min(thresholding[['specificity']][indx])}
#        
#        #Predict exceedances on the test set and add them to the results structure.
#        model <- model[['Threshold']](model, specificity)            
#        
#        #Open a file to which we will append the output.
#        sink(paste(output, paste(prefix, beach, m, "out", sep='.'), sep=""), append=TRUE)        
#        cat(paste("# Area under ROC curve = ", AreaUnderROC(ROC[[m]]), "\n", sep=''))
#        cat(paste("# aggregate.tpos = ", validation[[m]][['tpos']], "\n", sep=""))
#        cat(paste("# aggregate.tneg = ", validation[[m]][['tneg']], "\n", sep=""))
#        cat(paste("# aggregate.fpos = ", validation[[m]][['fpos']], "\n", sep=""))
#        cat(paste("# aggregate.fneg = ", validation[[m]][['fneg']], "\n", sep=""))
#        cat(paste("# variables: ", paste(model[['vars']], collapse=', '), "\n", sep=""))
#        cat(paste("# thresholding specificity: ", model[['specificity']], "\n", sep=""))
#        cat(paste("# decision threshold: ", model[['threshold']], "\n", sep=""))
#        
#        #Clean up and move on.
#        #OutputROC(ROC[method])
#        sink()            
#    }
}