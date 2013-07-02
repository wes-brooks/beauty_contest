#import numpy as np
import copy
import utils
import RDotNetWrapper as rdn
import array
import math

#Import the pls library into R, and connect python to R.
rdn.r.EagerEvaluate("library(adalasso)")
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
        #self.s = model_struct['s']
        self.formula = model_struct['formula']
        self.adapt = model_struct['adapt']
        self.overshrink = model_struct['overshrink']
        self.selectvars = model_struct['selectvars']
        
        #Get the data into R 
        self.nobs = len(self.data_dictionary[self.target])
        self.data_frame = utils.DictionaryToR(self.data_dictionary)
        self.data_dictionary = copy.copy(self.data_dictionary)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a logistic regression model in R.
        self.logistic_params = {'formula' : self.formula, \
            'family' : 'binomial', \
            'data' : self.data_frame, \
            'weights' : self.weights, \
            'verbose' : True, \
            'adapt' : self.adapt, \
            'overshrink' : self.overshrink, \
            'selectvars' : self.selectvars}
        self.model = r.Call(function='adalasso', **self.logistic_params).AsList()

        #Use cross-validation to find the best number of components in the model.
        self.GetActual()
        self.GetFitted()
        self.vars = [str(v) for v in self.model['lasso'].AsList()['vars'].AsVector()]
        
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
        
        #Set the direction for stepwise variable selection
        #try: self.s = s = args['lambda']
        #except KeyError: self.s = s = ''   

        try: self.adapt = args['adapt']
        except KeyError: self.adapt = False
        
        try: self.selectvars = args['selectvars']
        except KeyError: self.selectvars = False

        try: self.overshrink = args['overshrink']
        except KeyError: self.overshrink = False              
        
        #Get the data into R
        data = args['data']
        self.target = target = args['target']
        self.nobs = len(data[self.target])
        self.data_frame = utils.DictionaryToR(data)
        self.data_dictionary = copy.copy(data)
        self.predictors = len(self.data_dictionary.keys()) - 1
                
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
            'verbose' : True, \
            'adapt' : self.adapt, \
            'overshrink' : self.overshrink, \
            'selectvars' : self.selectvars}
        self.model = r.Call(function='adalasso', **self.logistic_params).AsList()
        
        #Select model components and a decision threshold
        self.GetActual()
        self.GetFitted()
        self.Threshold(self.specificity)
        self.vars = [str(v) for v in self.model['lasso'].AsList()['vars'].AsVector()]

        
    def AssignWeights(self, method=0):
        #Weight the observations in the training set based on their distance from the threshold.
        obs = self.data_dictionary[self.target]
        deviation = [(obs[i]-self.regulatory_threshold) / utils.std(obs) for i in range(len(obs))]
        
        #Integer weighting: weight is the observation's rounded-up whole number of standard deviations from the threshold.
        if method == 1: 
            weights = [1 for k in range(len(deviation))]
            breaks = range(int(math.floor(min(deviation))), int(math.ceil(max(deviation))))

            for i in breaks:
                #find all observations that meet the upper and lower criteria, separately
                first_slice = [k for k in range(len(deviation)) if deviation[k] > i]
                second_slice = [k for k in range(len(deviation)) if deviation < i+1]
                
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
        else: weights = [1.0 for k in range(len(deviation))]
            
        return weights
    
    
    def AssignLabels(self, raw):
        #Label observations as above or below the threshold.
        raw = array.array('d', [int(raw[k] > self.regulatory_threshold) for k in range(len(raw))])
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
        prediction = array.array('d', r.Call(function="predict.adalasso", **prediction_params).AsVector())

        #Translate the R output to a type that can be navigated in Python
        prob = [float(prediction[k]) for k in range(len(prediction))]
        return prob
        
        
    def PredictExceedances(self, data_dictionary):        
        prediction = self.Predict(data_dictionary)
        return [prediction[k] > self.threshold for k in range(len(prediction))]


    def Threshold(self, specificity=0.9):
        #Find the optimal decision threshold
        labels = self.data_dictionary[self.target]
        actual = self.actual
        fitted = self.fitted
        
        indx = [k for k in range(len(labels)) if labels[k] == 0]
        self.threshold = utils.Quantile([fitted[k] for k in indx], specificity)
        try: self.specificity = float(len([i for i in indx if fitted[i] <= self.threshold])) / len(indx)
        except ZeroDivisionError: self.specificity = 1


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
        
        return raw


    def GetActual(self):
        #Get the fitted values and residuals from the model.
        fitted = array.array('d', self.Extract('fitted.values').AsVector())
        residual = array.array('d', self.Extract('residuals').AsVector())
        
        self.actual = [fitted[k] + residual[k] for k in range(len(fitted))]
        
        
    def GetFitted(self, **params):
        #Get the fitted counts from the model so we can compare them to the actual counts.
        fitted = array.array('d', self.Extract('fitted.values').AsVector())
        self.fitted = list(fitted)
        self.residual = [self.actual[k] - self.fitted[k] for k in range(len(fitted))]
        
        
    def GetInfluence(self):
        #Get the model terms from R's model object
        terms = self.Extract('terms')
        terms = str(terms)
        
        #Get the covariate names
        self.names = self.data_dictionary.keys()
        self.names.remove(self.target)

        #Now get the model coefficients from R.
        coefficients = array.array('d', self.Extract('coef'))
        
        #Get the standard deviations (from the data_dictionary) and package the influence in a dictionary.
        raw_influence = list()
        
        for i in range( len(self.names) ):
            standard_deviation = utils.std(self.data_dictionary[self.names[i]])
            raw_influence.append(abs(standard_deviation * coefficients[i+1]))
            
        self.influence = dict(zip([raw_influence[k] / sum(raw_influence) for k in range(len(raw_influence))], self.names))
            
            
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
        elements_to_save = ["data_dictionary", "threshold", "specificity", "target", "regulatory_threshold", 'weights', 'formula', 'adapt', 'overshrink', 'selectvars']
        
        for element in elements_to_save:
            try: model_struct[element] = getattr(self, element)
            except KeyError: raise Exception('The required ' + element + ' was not found in the model to be serialized.')
            
        return model_struct
