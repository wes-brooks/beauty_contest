from modeling_pkg import pls, gbm, gam, logistic, lasso#, pls_parallel
methods = {'pls':pls, 'boosting':gbm, 'gbm':gbm, 'gam':gam, 'logistic':logistic, 'lasso':lasso}

import utils
import sys
import numpy as np
import copy

boosting_iterations = 2000


def Validate(data, target, method, folds='', **args):
    '''Creates a model and tests its performance with cross-validation.'''
    
    #Get the modeling module
    module = methods[method.lower()]
    
    #convert the data from a .NET DataTable or DataView into a numpy array
    if 'headers' not in args: [headers, data] = utils.DotnetToArray(data)
    else: headers = args['headers']
    target = str(target)
    regulatory = args['regulatory_threshold']
    
    #Randomly assign the data to cross-validation folds unless that has already been done.
    if folds=='': folds = 5
    if type(folds) is np.ndarray:
        fold = copy.copy(folds)
        folds = np.arange(max(folds)) + 1
    else:
        fold = utils.Partition(data, folds)
        folds = np.arange(folds) + 1
    
    #Set up the dictionary of all data.
    data_dict = dict( zip(headers, np.transpose(data)) )
    
    #Make a model for each fold and validate it.
    results = list()
    for f in folds:
        model_data = data[fold!=f,:]
        validation_data = data[fold==f,:]
        
        model_dict = dict(zip(headers, np.transpose(model_data)))
        validation_dict = dict(zip(headers, np.transpose(validation_data)))

        model = module.Model(data=model_dict, target=target, **args)  

        predictions = np.array(model.Predict(validation_dict))
        validation_actual = validation_dict[ target ]
        exceedance = np.array(validation_actual > regulatory, dtype=bool)
        
        fitted = np.array(model.fitted)
        actual = np.array(model.actual)
        candidates = fitted[np.where(actual < regulatory)]
        if len(candidates) == 0: candidates = fitted
        num_candidates = float(candidates.shape[0])
        num_exceedances = float(np.where(actual >= regulatory)[0].shape[0])
        
        specificity = list()
        sensitivity = list()
        threshold = list()
        tpos = list()
        tneg = list()
        fpos = list()
        fneg = list()
        total = model_data.shape[0]
        non_exceedances = float(sum(exceedance == False))
        exceedances = float(sum(exceedance == True))
        
        for prediction in predictions:
            tp = np.where(validation_actual[predictions >= prediction] >= regulatory)[0].shape[0]
            fp = np.where(validation_actual[predictions >= prediction] < regulatory)[0].shape[0]
            tn = np.where(validation_actual[predictions < prediction] < regulatory)[0].shape[0]
            fn = np.where(validation_actual[predictions < prediction] >= regulatory)[0].shape[0]
        
            tpos.append(tp)
            fpos.append(fp)
            tneg.append(tn)
            fneg.append(fn)
            
            try: candidate_threshold = np.max(candidates[np.where(candidates <= prediction)])
            except: candidate_threshold = np.min(candidates)
            specificity.append(np.where(fitted[actual < regulatory] < candidate_threshold)[0].shape[0] / num_candidates)
            sensitivity.append(np.where(fitted[actual >= regulatory] >= candidate_threshold)[0].shape[0] / num_exceedances)
            
            #the first candidate threshold that would be below this threshold
            try: threshold.append(max(fitted[fitted < prediction]))
            except: threshold.append(max(fitted))
        
        specificity = np.array(specificity)
        sensitivity = np.array(sensitivity)
        
        tpos = np.array(tpos)
        tneg = np.array(tneg)
        fpos = np.array(fpos)
        fneg = np.array(fneg)
        
        result = dict(threshold=threshold, sensitivity=sensitivity, specificity=specificity, tpos=tpos, tneg=tneg, fpos=fpos, fneg=fneg)
        results.append(result)

    model = module.Model(data=data_dict, target=target, **args)               
    
    return (results, model)
  
    
def SpecificityChart(results):
    '''Produces a list of lists that Virtual Beach turns into a chart of performance in prediction as we sweep the specificity parameter.'''
    specificities = list()    
    [specificities.extend(fold['specificity']) for fold in results]
    specificities = np.unique( np.sort(specificities) )
    
    spec = []
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
            indx = list(np.where(fold['specificity'] <= specificity)[0])
            if indx:
                indx = indx[ np.argmax(fold['specificity'][indx]) ]
            
                tpos[-1] += fold['tpos'][indx]
                fpos[-1] += fold['fpos'][indx]
                tneg[-1] += fold['tneg'][indx]
                fneg[-1] += fold['fneg'][indx]
            else:
                tpos[-1] = tpos[-1] + fold['tpos'][0] + fold['fneg'][0] #all exceedances correctly classified
                fpos[-1] = fpos[-1] + fold['tneg'][0] + fold['fpos'][0] #all non-exceedances incorrectly classified
        
    return [spec, tpos, tneg, fpos, fneg]
       

def ValidateGBM(model_dict, validation_dict, target, **args):
    '''Creates and tests prospective models using boosted decision trees.'''
    
    #Pick the model building parameters out of args
    try: weights = list( args['weights'] )   #Gradient-descent boosting, with observations down-weighted near the threshold.
    except KeyError: weights = ['both']

    try: costs = list( args['specificity'] )   #Gradient-descent boosting, with exceedances given more weight.
    except KeyError: costs = [1]

    costs = [ [1,i] for i in costs ]

    results = list()

    #Test models w/ midseason split
    for weight in weights:
        for cost in costs:
        
            l=gbm.Model(data=model_dict, target=target, cost=cost, weights=weight, iterations=boosting_iterations, **args)
 
            summary = Summarize(l, validation_dict, **args)
            #summary.insert( 1, weight)
            #summary.insert( 1, np.nan)
            
            results.append( summary )

    return results

    
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
    
    tp = float( sum(raw[:,0]) )  #True positives
    tn = float( sum(raw[:,1]) )  #True negatives
    fp = float( sum(raw[:,2]) )  #False positives
    fn = float( sum(raw[:,3]) )  #False negatives
    total = tp+tn+fp+fn
    
    return [spec_lim, tp, tn, fp, fn, total]
    
    
def Deserialize(model_struct, **args):
    '''Turns the model_struct into a Model object, using the method provided by model_struct['model_type']'''
    module = methods[ model_struct['model_type'].lower() ]
    return module.Model(model_struct=model_struct)
