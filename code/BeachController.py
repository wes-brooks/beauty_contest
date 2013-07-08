from modeling_pkg import adapt, pls, gbm, gam, logistic, lasso, adalasso, galm, adapt, galogistic, spls#, pls_parallel
methods = {'pls':pls, 'boosting':gbm, 'gbm-unweighted':gbm, 'gbmcv-unweighted':gbm, 'gbm-weighted':gbm, 'gbmcv-weighted':gbm, 'gam':gam, 'logistic':logistic, 'lasso':lasso, 'adalasso-unweighted':adalasso, 'adalasso-unweighted-preconditioned':adalasso,'adalasso-unweighted-select':adalasso, 'adalasso-weighted':adalasso, 'adalasso-weighted-select':adalasso, 'adalasso-weighted-preconditioned':adalasso, 'galm':galm, 'adapt':adapt, 'galogistic-unweighted':galogistic, 'galogistic-weighted':galogistic, 'precondition':adapt, 'spls':spls, 'spls-select':spls, 'adapt-select':adapt}

import utils
import sys
import copy
import array
import RDotNetWrapper as rdn
r = rdn.Wrap()

boosting_iterations = 2000


def Validate(data, target, method, folds='', **args):
    '''Creates a model and tests its performance with cross-validation.'''    
    #Get the modeling module
    module = methods[method.lower()]
    
    #convert the data from a .NET DataTable or DataView into an array
    if 'headers' not in args: [headers, data] = utils.DotNetToArray(data)
    else: headers = args['headers']
    target = str(target)
    regulatory = args['regulatory_threshold']
    
    #Randomly assign the data to cross-validation folds unless that has already been done.
    if folds=='': folds = 5
    try:
        fold = copy.copy(folds)
        folds = [k+1 for k in range(max(folds))]
    except TypeError:
        fold = utils.Partition(data, folds)
        folds = [k+1 for k in range(folds)]
    
    #Set up the dictionary of all data.
    data_dict = dict(zip(headers, [array.array('d', [row[i] for row in data]) for i in range(len(data[0]))])) #= dict( zip(headers, np.transpose(data)) )
    
    #Make a model for each fold and validate it.
    results = list()
    for f in folds:
        print "inner fold: " + str(f)
		
        model_data = [data[i] for i in range(len(data)) if fold[i] != f]
        validation_data = [data[i] for i in range(len(data)) if fold[i] == f]
        
        model_dict = dict(zip(headers, [array.array('d', [row[i] for row in model_data]) for i in range(len(model_data[0]))]))
        validation_dict = dict(zip(headers, [array.array('d', [row[i] for row in validation_data]) for i in range(len(validation_data[0]))]))
        
        model = module.Model(data=model_dict, target=target, **args)  

        predictions = model.Predict(validation_dict)
        validation_actual = validation_dict[target]
        exceedance = [validation_actual[i] > regulatory for i in range(len(validation_actual))]
        
		#Extract the necessary data, then clear R's object list to make room in memory
        fitted = model.fitted
        actual = model.actual
        objlist = list(r.Call('ls()').AsVector())
        print objlist
        print "in BeachController"      
        for obj in objlist: r.Remove(obj)
        r.GarbageCollection()
		
        candidates = [fitted[i] for i in range(len(fitted)) if actual[i] <= regulatory]
        if len(candidates) == 0: candidates = fitted
        num_candidates = len(candidates)
        num_exceedances = len([i for i in range(len(actual)) if actual[i] > regulatory])
        
        specificity = list()
        sensitivity = list()
        threshold = list()
        tpos = list()
        tneg = list()
        fpos = list()
        fneg = list()
        total = len(model_data)
        non_exceedances = float(len([i for i in range(len(exceedance)) if exceedance[i] == False]))
        exceedances = float(len([i for i in range(len(exceedance)) if exceedance[i] == True]))
        
        for candidate in candidates:
            #for prediction in predictions:
            #tp = np.where(validation_actual[predictions > prediction] > regulatory)[0].shape[0]
            tp = len([i for i in range(len(predictions)) if predictions[i] > candidate and validation_actual[i] > regulatory]) #np.where(validation_actual[predictions > candidate] > regulatory)[0].shape[0]
            #fp = np.where(validation_actual[predictions > prediction] <= regulatory)[0].shape[0]
            fp = len([i for i in range(len(predictions)) if predictions[i] > candidate and validation_actual[i] <= regulatory]) # np.where(validation_actual[predictions > candidate] <= regulatory)[0].shape[0]
            #tn = np.where(validation_actual[predictions <= prediction] <= regulatory)[0].shape[0]
            tn = len([i for i in range(len(predictions)) if predictions[i] <= candidate and validation_actual[i] <= regulatory]) #np.where(validation_actual[predictions <= candidate] <= regulatory)[0].shape[0]
            #fn = np.where(validation_actual[predictions <= prediction] > regulatory)[0].shape[0]
            fn = len([i for i in range(len(predictions)) if predictions[i] <= candidate and validation_actual[i] > regulatory]) #np.where(validation_actual[predictions <= candidate] > regulatory)[0].shape[0]
        
            tpos.append(tp)
            fpos.append(fp)
            tneg.append(tn)
            fneg.append(fn)
            
            try: candidate_threshold = candidate #np.max(candidates[np.where(candidates <= prediction)])
            except: candidate_threshold = min(candidates)
            
            try: specificity.append(tn / num_candidates)
            except ZeroDivisionError: specificity.append(1)
            
            try: sensitivity.append(tp / num_exceedances)
            except ZeroDivisionError: sensitivity.append(1)
            
            #the first candidate threshold that would be below this threshold, or the smallest candidate if none are below.
            #try: threshold.append(max(fitted[fitted < prediction]))
            try: threshold.append(candidate)
            except: threshold.append(min(fitted))
        
        #specificity = np.array(specificity)
        #sensitivity = np.array(sensitivity)
        
        #tpos = np.array(tpos)
        #tneg = np.array(tneg)
        #fpos = np.array(fpos)
        #fneg = np.array(fneg)
        
        result = dict(threshold=threshold, sensitivity=sensitivity, specificity=specificity, tpos=tpos, tneg=tneg, fpos=fpos, fneg=fneg)
        results.append(result)

    model = module.Model(data=data_dict, target=target, **args)               
    
    return (results, model)
  
    
def SpecificityChart(results):
    '''Produces a list of lists that Virtual Beach turns into a chart of performance in prediction as we sweep the specificity parameter.'''
    specificities = list()    
    [specificities.extend(fold['specificity']) for fold in results]
    specificities = list(set(specificities))
    specificities.sort()
    
    spec = []
    sens = []
    tpos = []
    tneg = []
    fpos = []
    fneg = []
    
    for specificity in specificities:
        tpos.append(0)
        tneg.append(0)
        fpos.append(0)
        fneg.append(0)
        spec.append(specificity)
        
        for fold in results:
            indx = [i for i in range(len(fold['specificity'])) if fold['specificity'][i] >= specificity]
            if indx:
                indx = sorted(range(len(indx)), key=indx.__getitem__)[0] #argmin of indx
            
                tpos[-1] += fold['tpos'][indx]
                fpos[-1] += fold['fpos'][indx]
                tneg[-1] += fold['tneg'][indx]
                fneg[-1] += fold['fneg'][indx]
            else:
                tpos[-1] = tpos[-1] + fold['tpos'][0] + fold['fneg'][0] #all exceedances correctly classified
                fpos[-1] = fpos[-1] + fold['tneg'][0] + fold['fpos'][0] #all non-exceedances incorrectly classified
                
        sens.append(float(tpos[-1]) / (tpos[-1] + fneg[-1]))
        
    return [spec, sens, tpos, tneg, fpos, fneg]

    
def Model(data_dict, target='', **args):
    '''Creates a Model object of the desired class, with the specified parameters.'''
    try: method = args['method']
    except KeyError: return "Error: did not specify a modeling method to Beach_Controller.Model"
    
    module = methods[ method.lower() ]
    model = module.Model(data=data_dict, target=target, **args)
    
    return model
    

def Summarize(model, validation_dict, **args):
    '''Summarizes the prediction results'''
    raw = model.Validate(validation_dict)
    
    if hasattr(model, 'breakpoint'): split = float( model.breakpoint )
    else: split = np.nan

    spec_lim = model.specificity
    
    if 'fold' in args: year = float( args['fold'] )
    elif 'year' in args: year = float( args['year'] )
    else: year = np.nan
    
    tp = float(sum([row[0] for row in raw]))  #True positives
    tn = float(sum([row[1] for row in raw]))  #True negatives
    fp = float(sum([row[2] for row in raw]))  #False positives
    fn = float(sum([row[3] for row in raw]))  #False negatives
    total = tp + tn + fp + fn
    
    return [spec_lim, tp, tn, fp, fn, total]
    
    
def Deserialize(model_struct, **args):
    '''Turns the model_struct into a Model object, using the method provided by model_struct['model_type']'''
    module = methods[ model_struct['model_type'].lower() ]
    return module.Model(model_struct=model_struct)
