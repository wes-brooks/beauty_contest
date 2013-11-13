library(devtools)
source('gbm.r')

beaches = list()
##beaches[['edgewater']] = list('file'='../data/edgewater.xls', 'target'='LogEC', 'transforms'=list(), 'remove'=c('id', 'year', 'month'), 'threshold'=2.3711)
##beaches[['redarrow']] = list('file'='../data/RedArrow2010-11_for_workshop.xls', 'target'='EColiValue', 'transforms'=list('EColiValue'=log10), 'remove'=c('pdate'), 'threshold'=2.3711)
##beaches[['redarrow']] = list('file'='../data/RA-VB1.xlsx', 'target'='logEC', 'remove'=c('beachEColiValue', 'CDTTime', 'beachTurbidityBeach', 'tribManitowocRiverTribTurbidity'), 'threshold'=2.3711, 'transforms'=c())
beaches[['hika']] = list('file'='../data/HK2013.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['fisher']] = list('file'='../data/Fisher.csv', 'target'='observation', 'remove'=c('beachEColiValue', 'datetime'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['kreher']] = list('file'='../data/Kreher.csv', 'target'='logecoli', 'remove'=c('beachEColiValue', 'dates'], 'threshold'=2.3711, 'transforms'=list())
#beaches[['maslowski']] = list('file'='../data/Maslowski.csv', 'target'='logecoli', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['neshotah']] = list('file'='../data/Neshotah.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['pointconcessions']] = list('file'='../data/PointConcessions.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['pointlakeshore']] = list('file'='../data/PointLakeshore.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['pointlighthouse']] = list('file'='../data/PointLighthouse.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['redarrow']] = list('file'='../data/RedArrow.csv', 'target'='logecoli', 'remove'=c('beachEColiValue', 'CDTTime'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['thompson']] = list('file'='../data/Thompson.csv', 'target'='observation', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
##beaches[['huntington']] = list('file'='../data/HuntingtonBeach.csv', 'target'='logecoli', 'remove'=c(), 'threshold'=2.3711, 'transforms'=list())

params = list()
##params[["lasso"]] = list('left'=0, 'right'=3.383743576, 'adapt'=True, 'overshrink'=True, 'precondition'=False)
#params[["PLS"]] = list()
params[["gbm-weighted"]] = list('depth'=5, 'weights'='discrete', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=0)
#params[["gbmcv-weighted"]] = list('depth'=5, 'weights'='discrete', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=5)
#params[["gbm-unweighted"]] = list('depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=0)
#params[["gbmcv-unweighted"]] = list('depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=5)
##params[["gam"]] = list('k'=50, 'julian'='jday')
##params[['logistic']] = list('weights'='discrete', 'stepdirection'='both')
#params[['galogistic-weighted']] = list('weights'='discrete', 'generations'=100, 'mutate'=0.05)
#params[['adalasso-weighted']] = list('weights'='discrete', 'adapt'=True, 'overshrink'=True, 'precondition'=False)
##params[['adalasso-weighted-preconditioned']] = list('weights'='discrete', 'adapt'=True, 'overshrink'=True, 'precondition'=True)
#params[['galogistic-unweighted']] = list('weights'='none', 'generations'=100, 'mutate'=0.05)
#params[['adalasso-unweighted']] = list('weights'='none', 'adapt'=True, 'overshrink'=True, 'precondition'=False)
#params[['adalasso-unweighted-select']] = list('weights'='none', 'adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=True)
#params[['adalasso-weighted-select']] = list('weights'='discrete', 'adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=True)
##params[['adalasso-unweighted-preconditioned']] = list('weights'='none', 'adapt'=False, 'overshrink'=True, 'precondition'=True)
#params[["galm"]] = list('generations'=5, 'mutate'=0.05)
#params[["adapt"]] = list('adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=False)
#params[["adapt-select"]] = list('adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=True)
#params[["spls"]] = list('selectvars'=False)
#params[["spls-select"]] = list('selectvars'=True)
##params[["precondition"]] = list('adapt'=False, 'overshrink'=True, 'precondition'=True)


params[["gbm"]] = list('depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=1000, 'shrinkage'=0.01, 'gbm.folds'=0)
methods = list('gbm'=GBM)

#methods = list('pls'=pls,
#	'boosting'=gbm,
#	'gbm-unweighted'=gbm,
#	'gbmcv-unweighted'=gbm,
#	'gbm-weighted'=gbm,
#	'gbmcv-weighted'=gbm,
#	'gam'=gam,
#	'logistic'=logistic,
#	'lasso'=lasso,
#	'adalasso-unweighted'=adalasso,
#	'adalasso-unweighted-preconditioned'=adalasso,
#	'adalasso-unweighted-select'=adalasso,
#	'adalasso-weighted'=adalasso,
#	'adalasso-weighted-select'=adalasso,
#	'adalasso-weighted-preconditioned'=adalasso,
#	'galm'=galm,
#	'adapt'=adapt,
#	'galogistic-unweighted'=galogistic,
#	'galogistic-weighted'=galogistic,
#	'precondition'=adapt,
#	'spls'=spls,
#	'spls-select'=spls,
#	'adapt-select'=adapt
#)


ValidationCounts = function(...) {
	return(
	  list(
	    tpos = 0,
	    tneg = 0,
	    fpos = 0,
	    fneg = 0,
	    predictions = list(),
	    truth = list()
	  )
	)
}


SpecificityChart = function(results) {
    #Produces a list of lists that Virtual Beach turns into a chart of performance in prediction as we sweep the specificity parameter.
    specificities = vector()    
	for (fold in results) {
        specificities = c(specificities, fold[['specificity']])
    }
    specificities = sort(unique(specificities))
    
    spec = vector()
    sens = vector()
    tpos = vector()
    tneg = vector()
    fpos = vector()
    fneg = vector()
    
    for (specificity in specificities) {
        tpos = c(tpos, 0)
        tneg = c(tneg, 0)
        fpos = c(fpos, 0)
        fneg = c(fneg, 0)
        spec = c(spec, specificity)
        
        for (fold in results) {
            indx = which(fold[['specificity']] >= specificity)
            if (length(indx) > 0) {
                indx = indx[which.min(fold[['specificity']][indx])] 
            
                tpos[length(tpos)] = tail(tpos, 1) + fold[['tpos']][indx]
                fpos[length(fpos)] = tail(fpos, 1) + fold[['fpos']][indx]
                tneg[length(tneg)] = tail(tneg, 1) + fold[['tneg']][indx]
                fneg[length(fneg)] = tail(fneg, 1) + fold[['fneg']][indx]
			} else {
                tpos[length(tpos)] = tail(tpos, 1) + fold[['tpos']][1] + fold[['fneg']][1] #all exceedances correctly classified
                fpos[length(fpos)] = tail(fpos, 1) + fold[['tneg']][1] + fold[['fpos']][1] #all non-exceedances incorrectly classified
			}
		}
        sens = c(sens, tail(tpos, 1) / (tail(tpos, 1) + tail(fneg, 1)))
	}
    list('specificity'=spec, 'sensitivity'=sens, 'tpos'=tpos, 'tneg'=tneg, 'fpos'=fpos, 'fneg'=fneg)
}



Partition = function(data, folds) {
    #Partition the data set into random, equal-sized folds for cross-validation
    #If we've called for leave-one-out CV (folds will be like 'n' or 'LOO' or 'leave-one-out')
    if (is.character(folds) || folds==nrow(data)) {
        fold = 1:nrow(data)
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
    results = list()
    for (f in ff) {
        print(paste("inner fold: ", f, sep=''))
		
        model_data = data[folds!=f,]
        validation_data = data[folds==f,]

        model <- module$Model
        model <- model[['Create']](self=model, data=model_data, target=target, ...)

        predictions = model[['Predict']](self=model, data=validation_data)
        validation_actual = validation_data[,target]
        exceedance = sapply(1:nrow(validation_data), function(i) {validation_actual[i] > regulatory})
        
		#Extract the necessary data, then clear R's object list to make room in memory
        fitted = model[['fitted']]
        actual = model[['actual']]        

        candidates = fitted[actual <= regulatory]
        if (length(candidates) == 0) {candidates = min(fitted)}
        num_nonexceedances = sum(validation_actual <= regulatory)
        num_exceedances = sum(validation_actual > regulatory)
        
        specificity = vector()
        sensitivity = vector()
        threshold = vector()
        tpos = vector()
        tneg = vector()
        fpos = vector()
        fneg = vector()
        total = nrow(model_data)
        non_exceedances = length(which(!exceedance))
        exceedances =  length(which(exceedance))
        
        for (candidate in candidates) {
            #for prediction in predictions:
            tp = sum(sapply(1:length(predictions), function(i) {predictions[i] > candidate && validation_actual[i] > regulatory}))
            fp = sum(sapply(1:length(predictions), function(i) {predictions[i] > candidate && validation_actual[i] <= regulatory}))
            tn = sum(sapply(1:length(predictions), function(i) {predictions[i] <= candidate && validation_actual[i] <= regulatory}))
            fn = sum(sapply(1:length(predictions), function(i) {predictions[i] <= candidate && validation_actual[i] > regulatory}))
        
            tpos = c(tpos, tp)
            fpos = c(fpos, fp)
            tneg = c(tneg, tn)
            fneg = c(fneg, fn)

            candidate_threshold = candidate
            
            if (num_nonexceedances==0) {specificity = c(specificity, 1)
            } else {specificity = c(specificity, tn / num_nonexceedances)}
            
			if (num_exceedances==0) {sensitivity = c(sensitivity, 1)
            } else {sensitivity = c(sensitivity, tp / num_exceedances)}
            
            #the first candidate threshold that would be below this threshold, or the smallest candidate if none are below.
            #try: threshold.append(max(fitted[fitted < prediction]))
            threshold = c(threshold, candidate)
		}
        
        result = list(fitted=fitted, train=actual, predicted=predicted, validate=validation_actual, threshold=threshold, sensitivity=sensitivity, specificity=specificity, tpos=tpos, tneg=tneg, fpos=fpos, fneg=fneg)
        results[[length(results) + 1L]] = result
	}
	
    model = module$Model
    args[['data']] = data
    args[['target']] = target
    args[['self']] = model
    model <- do.call(model[['Create']], args)

    return(list(results, model))
}

	
		

#We call this script with command line arguments from Condor
if (length(commandArgs()) > 1) {
    seeds = read.table("../seeds.txt")
    
    cluster = as.numeric(commandArgs(TRUE)[1])
    process = as.numeric(commandArgs(TRUE)[2]) + 1
    sites = names(beaches)
    
    s = length(sites)
    m = length(names(methods))
    d = c(process %/% s, process %% s)
    mm = c(d[1] %/% m, d[1] %% m)
    
    meth = mm[2] + 1
    site = d[2] + 1
    
    cat(paste("s: ", s, '\n', sep=""))
    cat(paste("m: ", m, '\n', sep=""))
    cat(paste("d: ", site, '\n', sep=""))
    cat(paste("mm: ", meth, '\n', sep=""))
    
    locs = sites[site]
    tasks = names(methods)[meth]
    seed = (1000 * seeds[s*mm[1]+site,]) %/% 1
    
    cat(paste("locs: ", locs, '\n', sep=""))
    cat(paste("tasks: ", tasks, '\n', sep=""))
    cat(paste("seed: ", seed, '\n', sep=""))
    
} else {
    cluster = "na"
    process = "na"
    locs = names(beaches)
    tasks = names(methods)
    seed = 0
}

    
cv_folds = 'loo'
result = "placeholder"
output = "../output/"

#Set the timestamp we'll use to identify the output files.
prefix = paste(cluster, process, sep=".")


AreaUnderROC = function(raw) {
    threshold = raw[['threshold']]
    nfolds = length(raw[['train']])
    tp = list()
    tn = list()
    fp = list()
    fn = list()
    sp = list()
    
    for (fold in 1:nfolds) {
        tpos = vector()
        tneg = vector()
        fpos = vector()
        fneg = vector()
        spec = vector()
        lenfold = length(raw[['train']][[fold]])
        lenpred = length(raw[['validate']][[fold]])
        
        training_exc = sapply(raw[['train']][[fold]], function(x) {x > threshold})
        training_nonexc = sapply(raw[['train']][[fold]], function(x) {x <= threshold})
        thresholds = raw[['fitted']][[fold]][which(training_nonexc)]
        rank = order(thresholds)
        
        for (i in 1:length(rank)) {
            k = rank[i]

            spec = c(spec, sum(sapply(1:length(thresholds), function(j) {thresholds[j] <= thresholds[k]})) / length(thresholds))
            tpos = c(tpos, sum(sapply(1:lenpred, function(j) {raw[['validate']][[fold]][j] > threshold && raw[['predicted']][[fold]][j] > thresholds[k]})))
            tneg = c(tneg, sum(sapply(1:lenpred, function(j) {raw[['validate']][[fold]][j] <= threshold && raw[['predicted']][[fold]][j] <= thresholds[k]})))
            fpos = c(fpos, sum(sapply(1:lenpred, function(j) {raw[['validate']][[fold]][j] <= threshold && raw[['predicted']][[fold]][j] > thresholds[k]})))
            fneg = c(fneg, sum(sapply(1:lenpred, function(j) {raw[['validate']][[fold]][j] > threshold && raw[['predicted']][[fold]][j] <= thresholds[k]})))
        }

        tp[[length(tp) + 1L]] = tpos
        tn[[length(tn) + 1L]] = tneg
        fp[[length(fp) + 1L]] = fpos
        fn[[length(fn) + 1L]] = fneg
        sp[[length(sp) + 1L]] = spec
    }
    
    specs = sort(unique(unlist(sp)))
    
    tpos = vector()
    tneg = vector()
    fpos = vector()
    fneg = vector()
    spec = vector()
    
    folds = length(tp)
    
    for (s in specs) {
        tpos = c(tpos, 0)
        tneg = c(tneg, 0)
        fpos = c(fpos, 0)
        fneg = c(fneg, 0)
        spec = c(spec, s)
        
        for (f in 1:nfolds) {
            indx = which(sp[[f]] >= s)
            indx = indx[which.min(sp[[f]][indx])]
            
            tpos[length(tpos)] = tail(tpos, 1) + tp[[f]][indx]
            tneg[length(tneg)] = tail(tneg, 1) + tn[[f]][indx]
            fpos[length(fpos)] = tail(fpos, 1) + fp[[f]][indx]
            fneg[length(fneg)] = tail(fneg, 1) + fn[[f]][indx]
		}
	}
            
    #Begin by assuming that we call every observation an exceedance
    area = 0
    spec_last = 0
    sens_last = 1
    
    for (k in 1:length(specs)) {
        sens = tpos[k] / (tpos[k] + fneg[k])
        sp = tneg[k] / (tneg[k] + fpos[k])
        area = area + (sp - spec_last) * sens
        sens_last = sens
        spec_last = sp
	}
        
    return(area)
}


#What SpecificityChart wants: dict(specificity=specificity, tpos=tpos, tneg=tneg, fpos=fpos, fneg=fneg)
set.seed(seed)
print(locs)

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
    validation = Map(ValidationCounts, names(methods))
    
    ROC = Map(function(x)
                {list('train'=list(), 'fitted'=list(), 'validate'=list(), 'predicted'=list(), 'threshold'=beaches[[beach]][['threshold']])},
                names(methods)
            )
    
    f=1
    #for (f in 1:max(folds)) {
    #    print(paste("outer fold: ", f, sep=""))
    #    
    #    #Break this fold into test and training sets.
    #    rr = which(folds != f)
    #    training_set = data[rr,]
    #    inner_cv = Partition(training_set, cv_folds)
    #    
    #    #Prepare the test set for use in prediction.
    #    rr = which(folds == f)
    #    test_set = data[rr,]
        
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
                list(data=data, #data=training_set,
                    target=beaches[[beach]][['target']],
                    method=method,
                    #folds=inner_cv,
                    folds=folds,
                    regulatory_threshold=beaches[[beach]][['threshold']]
                )
            )
            result = do.call(Validate, valpar)
            model = result[[2]]
            results = result[[1]]
            thresholding = SpecificityChart(results)
            
            #Set the threshold for predicting the reserved test set
            indx = which(sapply(1:length(thresholding[['tpos']]), function(i) {thresholding[['tpos']][i] >= thresholding[['fpos']][i]}))
            if (length(indx)==0) {specificity = 0.9}
            else {specificity = min(thresholding[['specificity']][indx])}
            
            #Predict exceedances on the test set and add them to the results structure.
            model <- model[['Threshold']](model, specificity)
            #predictions = model[['Predict']](self=model, data=test_set)
            truth = test_set[,beaches[[beach]][['target']]]
            
            #These will be used to calculate the area under the ROC curve:
            rank = order(truth)
            ROC[[method]][['validate']][[length(ROC[[method]][['validate']]) + 1L]] = truth
            ROC[[method]][['predicted']][[length(ROC[[method]][['predicted']]) + 1L]] = predictions
            ROC[[method]][['train']][[length(ROC[[method]][['train']]) + 1L]] = model[['actual']]
            ROC[[method]][['fitted']][[length(ROC[[method]][['fitted']]) + 1L]] = model[['fitted']]
            
            #Calculate the predictive perfomance for the model
            tpos = sum(sapply(1:length(predictions), function(i) {predictions[i] > model[['threshold']] && truth[i] > beaches[[beach]][['threshold']]}))
            tneg = sum(sapply(1:length(predictions), function(i) {predictions[i] <= model[['threshold']] && truth[i] <= beaches[[beach]][['threshold']]}))
            fpos = sum(sapply(1:length(predictions), function(i) {predictions[i] > model[['threshold']] && truth[i] <= beaches[[beach]][['threshold']]}))
            fneg = sum(sapply(1:length(predictions), function(i) {predictions[i] <= model[['threshold']] && truth[i] > beaches[[beach]][['threshold']]}))
            
            #Add predictive performance stats to the aggregate.
            validation[[method]][['tpos']] = validation[[method]][['tpos']] + tpos
            validation[[method]][['tneg']] = validation[[method]][['tneg']] + tneg
            validation[[method]][['fpos']] = validation[[method]][['fpos']] + fpos
            validation[[method]][['fneg']] = validation[[method]][['fneg']] + fneg
        
            #Store the performance information.
            #Open a file to which we will append the output.
            sink(paste(output, paste(prefix, beach, method, "out", sep='.'), sep=''), append=(f!=1))
            cat(paste("# fold = ", f, "\n", sep=""))
            cat(paste("# threshold = ", model[['threshold']], "\n", sep=""))
            cat(paste("# requested specificity = ", specificity, "\n", sep=""))
            cat(paste("# actual training-set specificity = ", model[['specificity']], "\n", sep=""))
            cat(paste("# tpos = ", tpos, "\n", sep=""))
            cat(paste("# tneg = ", tneg, "\n", sep=""))
            cat(paste("# fpos = ", fpos, "\n", sep=""))
            cat(paste("# fneg = ", fneg, "\n", sep=""))                
            cat("# raw predictions:\n")
            cat(predictions)
            cat("\n# truth:\n")
            cat(truth)
            cat("\n# fitted:\n")
            cat(model[['fitted']])
            cat("\n# actual:\n")
            cat(model[['actual']])
            cat("\n")
            sink()
        #}
    }
      
    for (m in tasks) {
        #Store the performance information.
        #First, create a model for variable selection:
        
        #Run this modeling method against the beach data.
        valpar = c(params[[m]],
            list(data=data,
                target=beaches[[beach]][['target']],
                method=method,
                folds=folds,
                regulatory_threshold=beaches[[beach]][['threshold']]
            )
        )
        result = do.call(Validate, valpar)
        model = result[[2]]
        results = result[[1]]
        thresholding = SpecificityChart(results)
        
        #Set the threshold for predicting the reserved test set
        indx = which(sapply(1:length(thresholding[['tpos']]), function(i) {thresholding[['tpos']][i] >= thresholding[['fpos']][i]}))
        if (length(indx)==0) {specificity = 0.9}
        else {specificity = min(thresholding[['specificity']][indx])}
        
        #Predict exceedances on the test set and add them to the results structure.
        model <- model[['Threshold']](model, specificity)            
        
        #Open a file to which we will append the output.
        sink(paste(output, paste(prefix, beach, m, "out", sep='.'), sep=""), append=TRUE)        
        cat(paste("# Area under ROC curve = ", AreaUnderROC(ROC[[m]]), "\n", sep=''))
        cat(paste("# aggregate.tpos = ", validation[[m]][['tpos']], "\n", sep=""))
        cat(paste("# aggregate.tneg = ", validation[[m]][['tneg']], "\n", sep=""))
        cat(paste("# aggregate.fpos = ", validation[[m]][['fpos']], "\n", sep=""))
        cat(paste("# aggregate.fneg = ", validation[[m]][['fneg']], "\n", sep=""))
        cat(paste("# variables: ", paste(model[['vars']], collapse=', '), "\n", sep=""))
        cat(paste("# thresholding specificity: ", model[['specificity']], "\n", sep=""))
        cat(paste("# decision threshold: ", model[['threshold']], "\n", sep=""))
        
        #Clean up and move on.
        #OutputROC(ROC[method])
        sink()            
    }
}
         
         
warnings()   
        