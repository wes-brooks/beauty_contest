Partition = function(data, folds) {
    #Partition the data set into random, equal-sized folds for cross-validation
    
    if (is.character(folds) || folds==nrow(data)) {
        if (tolower(substring(folds, 1, 1)) =='l') {
            #Leave-one-out:
            fold = 1:nrow(data)
        } else if (tolower(substring(folds, 1, 1)) =='y' && !is.null(data)) {
            #divide by years
            dates = as.character(as.POSIXlt(data[,1], format="%m/%d/%y %H:%M"))
            dates = strsplit(dates, split="-")
            years = sapply(dates, function(d) {d[1]})
            fold = unclass(as.factor(years))
        }
    } else { #Otherwise, randomly permute the data, then use contiguously-permuted chunks for CV
        #Initialization
        indices = 1:nrow(data)
        qq = as.numeric(quantile(1:folds, indices/nrow(data), type=1))
                
        #Now permute the fold assignments
        fold = sample(qq)
        }
        
    return(fold)
}


Validate = function(data, target, method, folds='', ...) {
    args = list(...)

    #Creates a model and tests its performance with cross-validation.
    #Get the modeling module
    module = methods[[tolower(method)]]
    
    #convert the data from a .NET DataTable or DataView into an array
    regulatory = args[['regulatory_threshold']]
    
    #Randomly assign the data to cross-validation folds unless that has already been done.
        ff = sort(unique(folds))
    
    #Make a model for each fold and validate it.
    results = as.data.frame(matrix(NA, nrow=0, ncol=3))
    for (f in ff) {
        print(paste("inner fold: ", f, sep=''))
                
        model_data = data[folds!=f,]
        validation_data = data[folds==f,]

        model <- module$Model
        model <- model[['Create']](self=model, data=model_data, target=target, args)

        predictions = model[['Predict']](self=model, data=validation_data)
        validation_actual = validation_data[,target]
        
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
        
        result = list(predicted=predictions, actual=validation_actual, threshold=threshold, fold=rep(f, length(threshold)))
        results = rbind(results, result)
    }
        
    tpos = tneg = fpos = fneg = rep(NA, nrow(results))
    
    for (k in 1:nrow(results)) {
        t = results$threshold[k]
        tpos[k] = length(which(results$threshold > t & results$actual > regulatory))
        tneg[k] = length(which(results$threshold <= t & results$actual <= regulatory))
        fpos[k] = length(which(results$threshold > t & results$actual <= regulatory))
        fneg[k] = length(which(results$threshold <= t & results$actual > regulatory))
    }
    
    results = cbind(results, tpos, tneg, fpos, fneg)
    results = results[order(results$threshold),]
        
    model = module$Model
    args[['data']] = data
    args[['target']] = target
    args[['self']] = model
    model <- do.call(model[['Create']], args)

    return(list(results, model))
}


ROC = function(results) {
	r = results
	
    #Begin by assuming that we call every observation an exceedance
    area = 0
    spec_last = 0
    sens_last = 1
    
    for (k in 1:nrow(r)) {
        sens = r$tpos[k] / (r$tpos[k] + r$fneg[k])
        sp = r$tneg[k] / (r$tneg[k] + r$fpos[k])
        area = area + (sp - spec_last) * sens
        sens_last = sens
        spec_last = sp
	}
        
    return(area)
}