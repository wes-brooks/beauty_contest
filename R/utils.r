Partition = function(data, folds, data=NULL) {
    #Partition the data set into random, equal-sized folds for cross-validation
    
    if (is.character(folds) || folds==nrow(data)) {
        if (tolower(substring(folds, 1, 1)) =='l') {
            #Leave-one-out:
            fold = 1:nrow(data)
        } else if (tolower(substring(folds, 1, 1)) =='y' && !is.null(data)) {
            #divide by years
            fold = 1:nrow(data)
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