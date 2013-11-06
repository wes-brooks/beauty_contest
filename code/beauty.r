library(devtools)
source_url("https://raw.github.com/wesesque/beauty_contest/master/code/gbm.r")

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

methods = list()
##methods[["lasso"]] = list('left'=0, 'right'=3.383743576, 'adapt'=True, 'overshrink'=True, 'precondition'=False)
#methods[["PLS"]] = list()
methods[["gbm-weighted"]] = list('depth'=5, 'weights'='discrete', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=0)
#methods[["gbmcv-weighted"]] = list('depth'=5, 'weights'='discrete', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=5)
#methods[["gbm-unweighted"]] = list('depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=0)
#methods[["gbmcv-unweighted"]] = list('depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=5)
##methods[["gam"]] = list('k'=50, 'julian'='jday')
##methods[['logistic']] = list('weights'='discrete', 'stepdirection'='both')
#methods[['galogistic-weighted']] = list('weights'='discrete', 'generations'=100, 'mutate'=0.05)
#methods[['adalasso-weighted']] = list('weights'='discrete', 'adapt'=True, 'overshrink'=True, 'precondition'=False)
##methods[['adalasso-weighted-preconditioned']] = list('weights'='discrete', 'adapt'=True, 'overshrink'=True, 'precondition'=True)
#methods[['galogistic-unweighted']] = list('weights'='none', 'generations'=100, 'mutate'=0.05)
#methods[['adalasso-unweighted']] = list('weights'='none', 'adapt'=True, 'overshrink'=True, 'precondition'=False)
#methods[['adalasso-unweighted-select']] = list('weights'='none', 'adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=True)
#methods[['adalasso-weighted-select']] = list('weights'='discrete', 'adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=True)
##methods[['adalasso-unweighted-preconditioned']] = list('weights'='none', 'adapt'=False, 'overshrink'=True, 'precondition'=True)
#methods[["galm"]] = list('generations'=5, 'mutate'=0.05)
#methods[["adapt"]] = list('adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=False)
#methods[["adapt-select"]] = list('adapt'=True, 'overshrink'=True, 'precondition'=False, 'selectvars'=True)
#methods[["spls"]] = list('selectvars'=False)
#methods[["spls-select"]] = list('selectvars'=True)
##methods[["precondition"]] = list('adapt'=False, 'overshrink'=True, 'precondition'=True)

methods = list('pls'=pls,
	'boosting'=gbm,
	'gbm-unweighted'=gbm,
	'gbmcv-unweighted'=gbm,
	'gbm-weighted'=gbm,
	'gbmcv-weighted'=gbm,
	'gam'=gam,
	'logistic'=logistic,
	'lasso'=lasso,
	'adalasso-unweighted'=adalasso,
	'adalasso-unweighted-preconditioned'=adalasso,
	'adalasso-unweighted-select'=adalasso,
	'adalasso-weighted'=adalasso,
	'adalasso-weighted-select'=adalasso,
	'adalasso-weighted-preconditioned'=adalasso,
	'galm'=galm,
	'adapt'=adapt,
	'galogistic-unweighted'=galogistic,
	'galogistic-weighted'=galogistic,
	'precondition'=adapt,
	'spls'=spls,
	'spls-select'=spls,
	'adapt-select'=adapt
)


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
	for (fold in results) {specificities = c(specificities, fold['specificity'])}
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
            indx = which(fold['specificity'][i] >= specificity)
            if indx {
                indx = order(indx)
            
                tail(tpos, 1) = tail(tpos, 1) + fold[['tpos']][indx]
                tail(fpos, 1) = tail(fpos, 1) + fold[['fpos']][indx]
                tail(tneg, 1) = tail(tneg, 1) + fold[['tneg']][indx]
                tail(fneg, 1) = tail(fneg, 1) + fold[['fneg']][indx]
			} else {
                tail(tpos, 1) = tail(tpos, 1) + fold[['tpos']][0] + fold[['fneg']][0] #all exceedances correctly classified
                tail(fpos, 1) = tail(fpos, 1) + fold[['tneg']][0] + fold[['fpos']][0] #all non-exceedances incorrectly classified
			}
		}
        sens = c(sens, tail(tpos, 1) / (tail(tpos, 1) + tail(fneg, 1))
	}
    list('specificity'=spec, 'sensitivity'=sens, 'tpos'=tpos, 'tneg'=tneg, 'fpos'=fpos, 'fneg'=fneg)
}



Partition = function(data, folds) {
    '''Partition the data set into random, equal-sized folds for cross-validation'''
    #If we've called for leave-one-out CV (folds will be like 'n' or 'LOO' or 'leave-one-out')
    if (is.character(folds) || folds==nrow(data)) {
        fold = 1:nrow(data)
    } else { #Otherwise, randomly permute the data, then use contiguously-permuted chunks for CV
        #Initialization
        indices = 1:nrow(data)
        qq = quantile(1:folds, indices / folds, type=1)    
		
        #Now permute the fold assignments
        fold = sample(qq)
	}
        
    return fold
}



Validate = function(data, target, method, folds='', ...) {
    #Creates a model and tests its performance with cross-validation.
    #Get the modeling module
    module = methods[method.lower()]
    
    #convert the data from a .NET DataTable or DataView into an array
    regulatory = args['regulatory_threshold']
    
    #Randomly assign the data to cross-validation folds unless that has already been done.
	ff = unique(folds)
    
    #Make a model for each fold and validate it.
    results = list()
    for (f in ff) {
        print(paste("inner fold: ", f, sep=''))
		
        model_data = data[folds!=f,]
        validation_data = data[folds==f,]

        model = module[['Model']](data=model_data, target=target, ...)  

        predictions = model[['Predict']](validation_data)
        validation_actual = validation_data[,target]
        exceedance = sapply(1:nrow(validation_data), function(i) {validation_actual[i] > regulatory})
        
		#Extract the necessary data, then clear R's object list to make room in memory
        fitted = model[['fitted']]
        actual = model[['actual']]
		
        candidates = fitted[actual <= regulatory]
        if (length(candidates) == 0) {candidates = min(fitted)}
        num_candidates = length(candidates)
        num_exceedances = length(which(actual > regulatory))
        
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
            tp = sum(sapply(1:length(predictions), function(i) {predictions[i] > candidate and validation_actual[i] > regulatory}))
            fp = sum(sapply(1:length(predictions), function(i) {predictions[i] > candidate and validation_actual[i] <= regulatory}))
            tn = sum(sapply(1:length(predictions), function(i) {predictions[i] <= candidate and validation_actual[i] <= regulatory}))
            fn = sum(sapply(1:length(predictions), function(i) {predictions[i] <= candidate and validation_actual[i] > regulatory}))
        
            tpos = c(tpos, tp)
            fpos = c(fpos, fp)
            tneg = c(tneg, tn)
            fneg = c(fneg, fn)
            
            candidate_threshold = candidate
            
            if (num_candidates==0) {specificity = c(specificity, 1)
            } else {specificity = c(specificity, tn / num_candidates)}
            
			if (num_exceedances==0) {sensitivity = c(sensitivity, 1)
            } else {sensitivity = c(sensitivity, tp / num_exceedances)}
            
            #the first candidate threshold that would be below this threshold, or the smallest candidate if none are below.
            #try: threshold.append(max(fitted[fitted < prediction]))
            threshold = c(threshold, candidate)
		}
        
        result = list(threshold=threshold, sensitivity=sensitivity, specificity=specificity, tpos=tpos, tneg=tneg, fpos=fpos, fneg=fneg)
        results = c(results, result)
	}

    model = module.Model(data=data, target=target, **args)               
    
    list(results, model)
}

	
		

#We call this script with command line arguments from Condor
if (length(commandArgs()) > 1) {
    seeds = read.table("../seeds.txt")
    
    cluster = int(commandArgs()[2])
    process = int(commandArgs()[3])
    sites = names(beaches)
    
    s = length(sites)
    m = length(names(methods))
    d = c(process %/% s, process %% s)
    mm = c(d[1] %/% m, d[1] %% m)
    
    print(paste("s: ", s, sep=""))
    print(paste("m: ", m, sep=""))
    print(paste("d: ", d, sep=""))
    print(paste("mm: ", mm, sep=""))
    
    locs = [sites[d[2]]]    
    tasks = [names(methods)[mm[2]]]
    seed = (1000 * seeds[s*mm[1]+d[2]]) %/% 1
    
    print(paste("locs: ", locs, sep=""))
    print(paste("tasks: ", tasks, sep=""))
    print(paste("seed: ", seed, sep=""))
    
} else (
    cluster = "na"
    process = "na"
    locs = beaches.keys()
    tasks = methods.keys()
    seed = ''
}

    
cv_folds = 5
B = 1
result = "placeholder"
output = "../output/"
#output = "../"

#Set the timestamp we'll use to identify the output files.
prefix = paste(cluster, process, sep=".")


AreaUnderROC = function(raw) {
    threshold = raw[['threshold']]
    nfolds = length(raw[['train']])
    tp = vector()
    tn = vector()
    fp = vector()
    fn = vector()
    sp = vector()
    
    for (fold in 1:nfolds) {
        tpos = vector()
        tneg = vector()
        fpos = vector()
        fneg = vector()
        spec = vector()
        lenfold = length(raw[['train']][[fold]])
        lenpred = length(raw[['validate']][[fold]])
        
        training_exc = sapply(raw['train'][fold], function(x) {x > threshold})
        training_nonexc = sapply(raw['train'][fold], function(x) {x <= threshold})
        thresholds = raw['fitted'][fold][i][which(training_nonexc)]
        rank = order(thresholds)
        
        for (i in 1:length(rank)) {
            k = rank[i]
            
            spec = c(spec, sum(sapply(1:length(thresholds), function(x) {thresholds[j] <= thresholds[k]})) / length(thresholds))
            tpos = c(tpos, sum(sapply(1:lenpred, function(x) {raw['validate'][fold][j] > threshold && raw['predicted'][fold][j] > thresholds[k]]})))
            tneg = c(tneg, sum(sapply(1:lenpred, function(x) {raw['validate'][fold][j] <= threshold && raw['predicted'][fold][j] <= thresholds[k]]})))
            fpos = c(fpos, sum(sapply(1:lenpred, function(x) {raw['validate'][fold][j] <= threshold && raw['predicted'][fold][j] > thresholds[k]]})))
            fneg = c(fneg, sum(sapply(1:lenpred, function(x) {raw['validate'][fold][j] > threshold && raw['predicted'][fold][j] <= thresholds[k]]})))
        
        tp[[length(tp) + 1L]] = tpos
        tn[[length(tn) + 1L]] = tneg
        fp[[length(fp) + 1L]] = fpos
        fn[[length(fn) + 1L]] = fneg
        sp[[length(sp) + 1L]] = spec
    
    specs = sort(unique(unlist(sp)))
    
    tpos = vector()
    tneg = vector()
    fpos = vector()
    fneg = vector()
    spec = vector()
    
    folds = len(tp)
    
    for (s in specs) {
        tpos = c(tpos, 0)
        tneg = c(tneg, 0)
        fpos = c(fpos, 0)
        fneg = c(fneg, 0)
        spec = c(spec, s)
        
        for (f in 1:folds) {
            indx = [i for i in range(len(sp[f])) if sp[f][i] >= s]
            indx = sorted(indx, key=sp[f].__getitem__)[0]
            
            tail(tpos, 1) = tail(tpos, 1) + tp[[f]][indx]
            tail(tneg, 1) = tail(tneg, 1) + tn[[f]][indx]
            tail(fpos, 1) = tail(fpos, 1) + fp[[f]][indx]
            tail(fneg, 1) = tail(fneg, 1) + fn[[f]][indx]
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
        
    return area
}

    
#def OutputROC(raw):
#    threshold = raw['threshold']
#    
#    tp = []
#    tn = []
#    fp = []
#    fn = []
#    sp = []
#    
#    for fold in range(len(raw['train'])):
#        tpos = []
#        tneg = []
#        fpos = []
#        fneg = []
#        spec = []
#        
#        training_exc = np.array(raw['train'][fold] > threshold, dtype=bool)
#        training_nonexc = np.array(raw['train'][fold] <= threshold, dtype=bool)
#        thresholds = raw['fitted'][fold][training_nonexc]
#        order = np.argsort(thresholds)
#        
#        for i in range(len(order)):
#            k = order[i]
#            test_exc = len(raw['validate'][fold] > thresholds[k])
#            train_exc = len(raw['train'][fold] > thresholds[k])
#            test_flag = len(raw['predicted'][fold] > thresholds[k])
#            train_flag = len(raw['fitted'][fold] > thresholds[k])
#            
#            spec.append(float(i+1)/len(thresholds))
#            tpos.append(np.where(raw['validate'][fold][raw['predicted'][fold] > thresholds[k]] > threshold)[0].shape[0])
#            tneg.append(np.where(raw['validate'][fold][raw['predicted'][fold] <= thresholds[k]] <= threshold)[0].shape[0])
#            fpos.append(np.where(raw['validate'][fold][raw['predicted'][fold] > thresholds[k]] <= threshold)[0].shape[0])
#            fneg.append(np.where(raw['validate'][fold][raw['predicted'][fold] <= thresholds[k]] > threshold)[0].shape[0])
#        
#        tp.append(tpos)
#        tn.append(tneg)
#        fp.append(fpos)
#        fn.append(fneg)
#        sp.append(np.array(spec, dtype=float))
#    
#    specs = []
#    [specs.extend(s) for s in sp]
#    specs = np.sort(np.unique(specs))
#    
#    tpos = []
#    tneg = []
#    fpos = []
#    fneg = []
#    spec = []
#    
#    folds = len(tp)
#    
#    for s in specs:
#        tpos.append(0)
#        tneg.append(0)
#        fpos.append(0)
#        fneg.append(0)
#        spec.append(s)
#        
#        for f in range(folds):
#            indx = list(np.where(sp[f] >= s)[0])
#            indx = indx[np.argmin(sp[f][indx])]
#            
#            tpos[-1] += tp[f][indx]
#            tneg[-1] += tn[f][indx]
#            fpos[-1] += fp[f][indx]
#            fneg[-1] += fn[f][indx]
#            
#    result = np.array([spec, tpos, tneg, fpos, fneg], dtype=float)
#    outfile = "../output/ROC.csv"
#    np.savetxt(outfile, result.T, delimiter=",")
    
    

#What SpecificityChart wants: dict(specificity=specificity, tpos=tpos, tneg=tneg, fpos=fpos, fneg=fneg)
random.seed(seed)
print(locs)

for (beach in locs) {
    first = dict(zip(tasks, [True for k in tasks]))

    #Read the beach's data.
    datafile = beaches[[beach]][["file"]
    
    data = read.csv(datafile)
    if ('remove' in beaches[[beach]]) {
        data = data[,!(names(data) %in% beaches[[beach]][['remove']])]
	}
	
    #Apply the specified transforms to the raw data.
    for (t in beaches[[beach]][['transforms']]) {
        data[:,t] = beaches[[beach]][['transforms']][[t]](data[:,t])
	}
    
    for (b in 1:B) {
        #Partition the data into cross-validation folds.
        folds = Partition(data, cv_folds)
        validation = Map(ValidationCounts, names(methods))
        
        ROC = Map(function(x)
					{list('train'=vector(), 'fitted'=vector(), 'validate'=vector(), 'predicted'=vector(), 'threshold'=beaches[[beach]][['threshold']])},
					names(methods)
				)
        
        for (f in 1:cv_folds) {
            print(paste("outer fold: ", f, sep=""))
			
            #Break this fold into test and training sets.
			rr = which(folds[i] != f)
            training_set = data[rr,]
            inner_cv = Partition(training_set, cv_folds)
            
            #Prepare the test set for use in prediction.
			rr = which(folds[i] == f)
            test_set = data[rr,]
            
            #Run the modeling routines.
            for (method in tasks) {
                if (first[[method]]) {
                    sink(paste(output, paste(prefix, beach, method, "out", sep="."), sep=''))            
                    if (seed) {cat(paste("# Seed = ", seed, "\n", sep=''))}
                    cat(paste("# Site = ", beach, "\n", sep=''))
                    cat(paste("# Method = ", method, "\n", sep=''))
                    sink()
                    first[[method]] = FALSE
				}
            
                #Run this modeling method against the beach data.
                result = Validate(training_set, beaches[[beach]][['target']], method=method, folds=inner_cv,
                                                        regulatory_threshold=beaches[[beach]][['threshold']], headers=headers, **methods[[method]])
                model = result[2]
                results = result[1]
                thresholding = SpecificityChart(results)
                
                #Set the threshold for predicting the reserved test set
                #indx = [i for i in range(len(thresholding['fneg'])) if thresholding['fneg'][i] >= thresholding['fpos'][i] and thresholding['specificity'][i] > 0.8]
                #if not indx:
                #    indx = [i for i in range(len(thresholding['fneg'])) if thresholding['specificity'][i] > 0.8]
                indx = which(sapply(1:length(thresholding[['fneg']]), function(i) {thresholding[['fneg']][i] >= thresholding[['fpos']][i]]}))
                if (length(indx)==0) {specificity = 0.9}
                else {specificity = min(thresholding[['specificity']][indx])}
                
                #Predict exceedances on the test set and add them to the results structure.
                model.Threshold(specificity)
                predictions = model.Predict(test_dict)
                truth = test_dict[,beaches[[beach]][['target']]]
                
                #These will be used to calculate the area under the ROC curve:
                order = sorted(range(len(truth)), key=truth.__getitem__)
                ROC[[method]][['validate']].append(truth)
                ROC[[method]][['predicted']].append(predictions)
                ROC[[method]][['train']].append(model.actual)
                ROC[[method]][['fitted']].append(model.fitted)
                
                #Calculate the predictive perfomance for the model
                tpos = sum(sapply(1:length(predictions), function(i) {predictions[i] > model.threshold && truth[i] > beaches[[beach]][['threshold']]}))
                tneg = sum(sapply(1:length(predictions), function(i) {predictions[i] <= model.threshold and truth[i] <= beaches[[beach]][['threshold']]}))
                fpos = sum(sapply(1:length(predictions), function(i) {predictions[i] > model.threshold and truth[i] <= beaches[[beach]][['threshold']]}))
                fneg = sum(sapply(1:length(predictions), function(i) {predictions[i] <= model.threshold and truth[i] > beaches[[beach]][['threshold']]}))
                
                #Add predictive performance stats to the aggregate.
                validation[[method]][['tpos']] = validation[[method]][['tpos']] + tpos
                validation[[method]][['tneg']] = validation[[method]][['tneg']] + tneg
                validation[[method]][['fpos']] = validation[[method]][['fpos']] + fpos
                validation[[method]][['fneg']] = validation[[method]][['fneg']] + fneg
            
                #Store the performance information.
                #Open a file to which we will append the output.
				sink(paste(output, paste(prefix, beach, method, "out", sep='.')))
                cat(paste("# fold = ", f, "\n", sep=""))
                cat(paste("# threshold = ", model.threshold, "\n", sep=""))
                cat(paste("# requested specificity = ", specificity, "\n", sep=""))
                cat(paste("# actual training-set specificity = ", model.specificity, "\n", sep=""))
                cat(paste("# tpos = ", tpos, "\n", sep=""))
                cat(paste("# tneg = ", tneg, "\n", sep=""))
                cat(paste("# fpos = ", fpos, "\n", sep=""))
                cat(paste("# fneg = ", fneg, "\n", sep=""))                
                cat("# raw predictions:\n")
                cat(predictions)
                cat("# truth:\n")
                cat(truth)
                cat("# fitted:\n")
                cat(model.fitted)
                cat("# actual:\n")
                cat(model.actual)
                sink()
			}
            
        for (m in tasks) {
            #Store the performance information.
            #First, create a model for variable selection:
            model = Interface.Control.methods[[m.lower()]].Model(data=data, target=beaches[[beach]][['target']], regulatory_threshold=beaches[[beach]][['threshold']], **methods[[m]])
            
            #Open a file to which we will append the output.
            sink(paste(output, paste(prefix, beach, m, "out", sep='.'), sep=""))            
            cat(paste("# Area under ROC curve = ", AreaUnderROC(ROC[m]) + "\n"))
            cat(paste("# aggregate.tpos = ", validation[[m]][['tpos']], "\n", sep=""))
            cat(paste("# aggregate.tneg = ", validation[[m]][['tneg']], "\n", sep=""))
            cat(paste("# aggregate.fpos = ", validation[[m]][['fpos']], "\n", sep=""))
            cat(paste("# aggregate.fneg = ", validation[[m]][['fneg']], "\n", sep=""))
            cat(paste("# variables: ", paste(model[['vars']], collapse=', '), "\n", sep=""))
            cat(paste("# decision threshold: ", model[['threshold']], "\n", sep=""))
            
            #Clean up and move on.
			#OutputROC(ROC[method])
            sink()            
		}
	}
}
            
        