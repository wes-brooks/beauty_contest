import numpy as np
import random
import copy
import re
from random import choice
import utils
import RDotNetWrapper as rdn

#Import the pls library into R, and connect python to R.
rdn.r.EagerEvaluate("library(censlars)") 
r = rdn.Wrap()


class Model(object): 
    '''represents a PLS model generated in R'''

    def __init__(self, **args):
        if "model_struct" in args: self.Deserialize( args['model_struct'] )
        else: self.Create(**args)
        
        
    def Deserialize(self, model_struct):
        #Unpack the model_struct dictionary
        self.data_dictionary = model_struct['data_dictionary']
        self.target = model_struct['target']
        self.specificity = model_struct['specificity']
        self.left = model_struct['left']
        self.right = model_struct['right']
        
        #Get the data into R 
        self.data_frame = utils.DictionaryToR(self.data_dictionary)
        self.data_dictionary = copy.deepcopy(self.data_dictionary)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a PLS model in R.
        self.formula = r.Call('as.formula', obj=utils.SanitizeVariableName(self.target) + '~.')
        self.pls_params = {'formula' : self.formula, \
            'data' : self.data_frame, \
            'left' : self.left, \
            'right' : self.right }
        self.model = r.Call(function='censlars', **self.pls_params).AsList()
                            
        #Get some information out of the model.
        self.GetActual()
        self.GetFitted()
        
        #Establish a decision threshold
        self.specificity = model_struct['specificity']
        self.threshold = model_struct['threshold']
        self.regulatory_threshold = model_struct['regulatory_threshold']
    
    
    def Create(self, **args):
        #Check to see if a threshold has been specified in the function's arguments
        if 'regulatory_threshold' in args: self.threshold = args['regulatory_threshold']
        else: self.threshold = 2.3711   # if there is no 'threshold' key, then use the default (2.3711)
        self.regulatory_threshold = self.threshold

        self.target = args['target']
        
        if 'left' in args: self.left=args['left']
        else: self.left=-np.inf
        
        if 'right' in args: self.right=args['right']
        else: self.right=np.inf
        
        if 'specificity' in args: specificity=args['specificity']
        else: specificity=0.9
        
        #Get the data into R
        data = args['data']
        self.data_frame = utils.DictionaryToR(data)
        self.data_dictionary = copy.deepcopy(data)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a PLS model in R.
        self.formula = r.Call('as.formula', obj=utils.SanitizeVariableName(self.target) + '~.')
        self.pls_params = {'formula' : self.formula, \
            'data' : self.data_frame, \
            'left' : self.left, \
            'right' : self.right }
        self.model = r.Call(function='censlars', **self.pls_params).AsList()
                
        #Get some information out of the model
        self.GetActual()
        self.GetFitted()
        
        #Establish a decision threshold
        self.Threshold(specificity)


    def Extract(self, model_part, **args):
        try: container = args['extract_from']
        except KeyError: container = self.model
        
        #use R's coef function to extract the model coefficients
        if model_part == 'coef':
            part = list(r.Call(function='coef', object=self.model, ncomp=self.ncomp, intercept=True).AsVector())
            
        #use R's MSEP function to estimate the variance.
        elif model_part == 'MSEP':
            part = self.model['lars']['MSEP']
            
        #use R's RMSEP function to estimate the standard error.
        elif model_part == 'RMSEP':
            part = self.model['lars']['RMSEP']
        
        #Get the variable names, ordered as R sees them.
        elif model_part == 'names':
            part = ["Intercept"]
            part.extend(self.model['lars']['vars'])
            try: part.remove(utils.SanitizeVariableName(self.target))
            except: pass
        
        #otherwise, go to the data structure itself
        else:
            part = container[model_part]
            
        return part


    def PredictValues(self, data_dictionary, **args):
        data_frame = utils.DictionaryToR(data_dictionary)
        prediction_params = {'object': self.model, 'newdata': data_frame }
        
        prediction = r.Call(function='predict.censlars', **prediction_params).AsVector()
        prediction = np.array(prediction, dtype=float)

        return prediction
        
        
    def PredictExceedances(self, data_dictionary, **kwargs):
        prediction = self.PredictValues(data_dictionary)
        return np.array(prediction >= self.threshold, dtype=int)
        
        
    def PredictExceedanceProbability(self, data_dictionary, **kwargs):
        prediction = self.PredictValues(data_dictionary).squeeze()
        se = self.Extract('RMSEP')
        nonexceedance_probability = r.Call(function='pnorm', q=np.array((self.threshold-prediction)/se, dtype=float)).AsVector()
        exceedance_probability = [float(1-item) for item in nonexceedance_probability]
        return exceedance_probability

        
    def Predict(self, data_dictionary, **kwargs):
        prediction = self.PredictValues(data_dictionary)
        return [float(item) for item in prediction.squeeze()]
        

    def Threshold(self, specificity=0.92):
        self.specificity = specificity
    
        if not hasattr(self, 'actual'):
            self.GetActual()
        
        if not hasattr(self, 'fitted'):
            self.GetFitted()

        #Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
        try:
            non_exceedances = self.array_fitted[np.where(self.array_actual < self.regulatory_threshold)[0]]
            self.threshold = utils.Quantile(non_exceedances, specificity)
            self.specificity = float(sum(non_exceedances < self.threshold))/non_exceedances.shape[0]

        #This error should only happen if somehow there are no non-exceedances in the training data.
        except ZeroDivisionError:
            self.threshold = self.regulatory_threshold        
            self.specificity = 1


    def GetActual(self):
        fitted_values = np.array(self.model['censreg']['actual'].AsVector())

        #Recover the actual counts by adding the residuals to the fitted counts.
        residual_values = np.array(self.model['lars']['residuals'].AsVector())
        residual_values = residual_values.transpose()
        
        self.array_actual = np.array(fitted_values+residual_values).squeeze()
        self.actual = list(self.array_actual)
        
        
    def GetFitted(self, **params):            
        fitted_values = np.array(self.model['lars']['fitted'].AsVector())
        
        self.array_fitted = fitted_values
        self.array_residual = self.array_actual - self.array_fitted
        
        self.fitted = list(self.array_fitted)
        self.residual = list(self.array_residual)
        
        
    def GetInfluence(self):        
        #Get the covariate names
        self.names = self.data_dictionary.keys()
        self.names.remove(self.target)

        #Now get the model coefficients from R.
        coefficients = np.array( self.Extract('coef') )
        coefficients = coefficients.flatten()
        
        #Get the standard deviations (from the data_dictionary) and package the influence in a dictionary.
        raw_influence = list()
        
        for i in range( len(self.names) ):
            standard_deviation = np.std( self.data_dictionary[self.names[i]] )
            raw_influence.append( float(abs(standard_deviation * coefficients[i+1])) )
 
        self.influence = dict( zip([float(x/sum(raw_influence)) for x in raw_influence], self.names) )
        return self.influence
            
            
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
                if self.actual[obs] >= 2.3711: t_pos += 1
                else: f_pos += 1
            else:
                if self.actual[obs] >= 2.3711: f_neg += 1
                else: t_neg += 1
        
        return [t_pos, t_neg, f_pos, f_neg]
        
        
    def Serialize(self):
        model_struct = dict()
        model_struct['model_type'] = 'lasso'
        elements_to_save = ["data_dictionary", "threshold", "specificity", "target", "regulatory_threshold", "left", "right"]
        
        for element in elements_to_save:
            try: model_struct[element] = getattr(self, element)
            except KeyError: raise Exception('The required ' + element + ' was not found in the model to be serialized.')
            
        return model_struct
        
        
    def ToString(self):
        return "LASSO model"