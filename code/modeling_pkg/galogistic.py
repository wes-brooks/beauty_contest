import numpy as np
import copy
import utils
import RDotNetWrapper as rdn

#Import the pls library into R, and connect python to R.
rdn.r.EagerEvaluate("library(galogistic)")
r = rdn.Wrap()


class Model(object): 
    '''represents a logistic regression model generated in R'''

    def __init__(self, **args):
        if "model_struct" in args: self.Deserialize( args['model_struct'] )
        else: self.Create(**args)
    
    
    def Deserialize(self, model_struct):
        #Unpack the model_struct dictionary
        self.data_dictionary = model_struct['data_dictionary']
        self.target = model_struct['target']
        self.specificity = model_struct['specificity']
        self.weights = model_struct['weights']
        self.population = model_struct['population']
        self.generations = model_struct['generations']
        self.mutate = model_struct['mutate']
        self.ZOR = model_struct['ZOR']
        self.formula = model_struct['formula']
        
        #Get the data into R 
        self.nobs = len(self.data_dictionary[self.target])
        self.data_frame = utils.DictionaryToR(self.data_dictionary)
        self.data_dictionary = copy.deepcopy(self.data_dictionary)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a logistic regression model in R.
        self.logistic_params = {'formula' : self.formula, \
            'family' : 'binomial', \
            'data' : self.data_frame, \
            'weights' : self.weights, \
            'family' : 'binomial', \
            'population' : self.population, \
            'generations' : self.generations, \
            'mutateRate' : self.mutate, \
            'zeroOneRatio' : self.ZOR, \
            'verbose' : True }
        self.model = r.Call(function='galogistic', **self.logistic_params).AsList()

        #Use cross-validation to find the best number of components in the model.
        self.GetActual()
        self.GetFitted()
        
        #Establish a decision threshold
        self.specificity = model_struct['specificity']
        self.threshold = model_struct['threshold']
        self.regulatory_threshold = model_struct['regulatory_threshold']
    
    
    def Create(self, **args):
        #Create a logistic model object
    
        #Check to see if a threshold has been specified in the function's arguments
        try: self.regulatory_threshold = args['regulatory_threshold']
        except KeyError: self.regulatory_threshold = 2.3711   # if there is no 'threshold' key, then use the default (2.3711)
        
        #Check to see if a specificity has been specified in the function's arguments
        try: self.specificity = args['specificity']
        except KeyError: self.specificity = 0.9

        #Get the data into R
        data = args['data']
        self.target = target = args['target']
        self.nobs = len(data[self.target])
        self.data_frame = utils.DictionaryToR(data)
        self.data_dictionary = copy.deepcopy(data)
        self.predictors = len(self.data_dictionary.keys()) - 1
                
        if 'population' in args: self.population=args['population']
        else: self.population=200
        
        if 'generations' in args: self.generations=args['generations']
        else: self.generations=100
        
        if 'mutate' in args: self.mutate=args['mutate']
        else: self.mutate=0.02
        
        if 'ZOR' in args: self.ZOR=args['ZOR']
        else: self.ZOR=10       
         
        #Check to see if a weighting method has been specified in the function's arguments
        try:
            #integer (discrete) weighting
            if str(args['weights']).lower()[0] in ['d', 'i']: 
                self.weights = self.AssignWeights(method=1)
                
            #float (continuous) weighting
            elif str(args['weights']).lower()[0] in ['c', 'f']: 
                self.weights = self.AssignWeights(method=2)
                
            else: self.weights = self.AssignWeights(method=0) 
                
        #If there is no 'weights' key, set all weights to one.
        except KeyError: 
            self.weights = self.AssignWeights(method=0) 
        
        #Label the exceedances in the training set.
        self.data_dictionary[target] = self.AssignLabels(self.data_dictionary[target])
        
        #Get the data into R 
        self.data_frame = utils.DictionaryToR(self.data_dictionary)
                        
        #Generate a logistic regression model in R.
        self.formula = formula = r.Call('as.formula', obj=utils.SanitizeVariableName(self.target) + '~ .')
        self.logistic_params = {'formula' : formula, \
            'family' : 'binomial', \
            'data' : self.data_frame, \
            'weights' : self.weights, \
            'family' : 'binomial', \
            'population' : self.population, \
            'generations' : self.generations, \
            'mutateRate' : self.mutate, \
            'zeroOneRatio' : self.ZOR, \
            'verbose' : True }
        self.model = r.Call(function='galogistic', **self.logistic_params).AsList()
        
        #Select model components and a decision threshold
        self.GetActual()
        self.GetFitted()
        self.Threshold(self.specificity)

        
    def AssignWeights(self, method=0):
        #Weight the observations in the training set based on their distance from the threshold.
        deviation = (self.data_dictionary[self.target]-self.regulatory_threshold)/np.std(self.data_dictionary[self.target])
        
        #Integer weighting: weight is the observation's rounded-up whole number of standard deviations from the threshold.
        if method == 1: 
            weights = np.ones( len(deviation) )
            breaks = range( int( np.floor(min(deviation)) ), int( np.ceil(max(deviation)) ) )

            for i in breaks:
                #find all observations that meet the upper and lower criteria, separately
                first_slice = np.where(deviation > i)[0]
                second_slice = np.where(deviation < i+1)[0]
                
                #now find all the observations that meet both criteria simultaneously
                rows = filter( lambda x: x in first_slice, second_slice )
                rows = [int(r) for r in rows]
                
                #Decide how many times to replicate each slice of data
                if i<0:
                    replicates = (abs(i) - 1)
                else:
                    replicates = i
                    
                if rows: weights[rows] = replicates + 1
                
        #Continuous weighting: weight is the observation's distance (in standard deviations) from the threshold.      
        elif method == 2:
            weights = abs(deviation)
            
        #No weights: all weights are one.
        else: weights = np.ones( len(deviation) )
            
        return weights
    
    
    def AssignLabels(self, raw):
        #Label observations as above or below the threshold.
        raw = np.array(raw >= self.regulatory_threshold, dtype=int)
        return raw
    

    def Extract(self, model_part, **args):
        try: container = args['extract_from']
        except KeyError: container = self.model
        
        #use R's coef function to extract the model coefficients
        if model_part == 'coef':
            part = r.coef(self.model, intercept=True)
        
        #otherwise, go to the data structure itself
        else:
            part = container[model_part]
            
        return part


    def Predict(self, data_dictionary):
        data_frame = utils.DictionaryToR(data_dictionary)
        prediction_params = {'obj':self.model, 'newx':data_frame}
        prediction = r.Call(function="predict.galogistic", **prediction_params).AsVector()

        #Translate the R output to a type that can be navigated in Python
        prob = np.array(prediction).squeeze()
        return prob
        
        
    def PredictExceedances(self, data_dictionary):        
        prediction = self.Predict(data_dictionary)
        return np.array(prediction >= self.threshold, dtype=int)


    def Threshold(self, specificity=0.92):
        self.specificity = specificity
    
        if not hasattr(self, 'actual'):
            self.GetActual()
        
        if not hasattr(self, 'fitted'):
            self.GetFitted()

        #Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
        try:
            non_exceedances = self.array_fitted[np.where(self.array_actual <= self.regulatory_threshold)[0]]
            self.threshold = utils.Quantile(non_exceedances, specificity)
            self.specificity = float(sum(non_exceedances <= self.threshold))/non_exceedances.shape[0]

        #This error should only happen if somehow there are no non-exceedances in the training data.
        except ZeroDivisionError:
            self.threshold = self.regulatory_threshold        
            self.specificity = 1


    def Validate(self, data_dictionary):
        predictions = self.Predict(data_dictionary)
        actual = data_dictionary[self.target]

        p = predictions

        raw = list()
    
        for k in range(len(predictions)):
            t_pos = int(predictions[k] > self.threshold and actual[k] > self.regulatory_threshold)
            t_neg = int(predictions[k] <= self.threshold and actual[k] <= self.regulatory_threshold)
            f_pos = int(predictions[k] > self.threshold and actual[k] <= self.regulatory_threshold)
            f_neg = int(predictions[k] <= self.threshold and actual[k] > self.regulatory_threshold)
            raw.append([t_pos, t_neg, f_pos, f_neg])
        
        raw = np.array(raw)
        
        return raw


    def GetActual(self):
        fitted = np.array(self.model['actual'].AsVector())
        
        #Recover the actual counts by adding the residuals to the fitted counts.
        residuals = np.array(self.model['residuals'].AsVector())
        #residuals = residual_values.transpose()
        
        self.array_actual = np.array(fitted + residuals).squeeze()
        self.actual = list(self.array_actual)
        
        
    def GetFitted(self, **params):            
        fitted = np.array(self.model['fitted'].AsVector())
        
        self.array_fitted = fitted
        self.array_residual = self.array_actual - self.array_fitted
        
        self.fitted = list(self.array_fitted)
        self.residual = list(self.array_residual)
            
            
    def Count(self):
        #Count the number of true positives, true negatives, false positives, and false negatives.
        self.GetActual()
        self.GetFitted()
        
        #initialize counts to zero:
        t_pos = 0
        t_neg = 0
        f_pos = 0
        f_neg = 0
        
        for obs in range( len(self.fitted) ):
            if self.fitted[obs] >= self.threshold:
                if self.actual[obs] >= self.regulatory_threshold: t_pos += 1
                else: f_pos += 1
            else:
                if self.actual[obs] >= self.regulatory_threshold: f_neg += 1
                else: t_neg += 1
        
        return [t_pos, t_neg, f_pos, f_neg]
        
        
    def Plot(self, **plotargs ):
        try:
            ncomp = plotargs['ncomp']
            if type(ncomp)==str: plotargs['ncomp']=self.ncomp
                
        except KeyError: pass
        
        r['''dev.new''']()
        r.plot(self.model, **plotargs)

        
    def Serialize(self):
        model_struct = dict()
        model_struct['model_type'] = 'logistic'
        elements_to_save = ["data_dictionary", "threshold", "specificity", "target", "regulatory_threshold", 'weights', "population", 'generations', 'mutate', 'ZOR', 'formula']
        
        for element in elements_to_save:
            try: model_struct[element] = getattr(self, element)
            except KeyError: raise Exception('The required ' + element + ' was not found in the model to be serialized.')
            
        return model_struct
