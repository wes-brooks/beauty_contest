#import numpy as np
import random
import copy
import re
from random import choice
import utils
import RDotNetWrapper as rdn
import array

#Import the pls library into R, and connect python to R.
rdn.r.EagerEvaluate("library(spls.wrap)") 
r = rdn.Wrap()


class Model(object): 
    '''represents an sPLS model generated in R'''

    def __init__(self, **args):
        if "model_struct" in args: self.Deserialize( args['model_struct'] )
        else: self.Create(**args)
        
        
    def Deserialize(self, model_struct):
        #Unpack the model_struct dictionary
        self.data_dictionary = model_struct['data_dictionary']
        self.target = model_struct['target']
        self.specificity = model_struct['specificity']
        self.selectvars = model_struct['selectvars']
        
        #Get the data into R 
        self.data_frame = utils.DictionaryToR(self.data_dictionary)
        self.data_dictionary = copy.copy(self.data_dictionary)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a PLS model in R.
        self.formula = r.Call('as.formula', obj=utils.SanitizeVariableName(self.target) + '~.')
        self.spls_params = {'formula' : self.formula, \
            'data' : self.data_frame, \
            'selectvars' : self.selectvars}
        self.model = r.Call(function='spls.wrap', **self.spls_params).AsList()
                            
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
        
        if 'selectvars' in args: self.selectvars=args['selectvars']
        else: self.selectvars=False
        
        if 'specificity' in args: specificity=args['specificity']
        else: specificity=0.90
        
        #Get the data into R
        data = args['data']
        self.data_frame = utils.DictionaryToR(data)
        self.data_dictionary = copy.copy(data)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a PLS model in R.
        self.formula = r.Call('as.formula', obj=utils.SanitizeVariableName(self.target) + '~.')
        self.spls_params = {'formula' : self.formula, \
            'data' : self.data_frame, \
            'selectvars' : self.selectvars}
        self.model = r.Call(function='spls.wrap', **self.spls_params).AsList()
                
        #Get some information out of the model
        self.GetActual()
        self.GetFitted()
        self.vars = [str(v) for v in self.model['vars'].AsVector()]
        
        #Establish a decision threshold
        self.Threshold(specificity)


    def Extract(self, model_part, **args):
        try: container = args['extract_from']
        except KeyError: container = self.model
        
        #use R's coef function to extract the model coefficients
        #if model_part == 'coef':
        #    step = self.model['lars'].AsList()['lambda.index'].AsVector()[0] #r.Call(function='coef', object=self.model, ncomp=self.ncomp, intercept=True).AsList()
        #    coefobj = r.Call(function='coef', object=self.model.lars.AsList().model, mode='step', s=step)
        #    names = list(r.Call(function='names', x=coefobj).AsVector())
        #    coefs = list(coefobj.AsVector())
        #    part = dict(zip(names, coefs))
        
        #use R's MSEP function to estimate the variance.
        #elif model_part == 'MSEP':
        #    part = self.model['lars']['MSEP']
            
        #use R's RMSEP function to estimate the standard error.
        #elif model_part == 'RMSEP':
        #    part = self.model['lars']['RMSEP']
        
        #Get the variable names, ordered as R sees them.
        #elif model_part == 'names':
        #    part = ["Intercept"]
        #    part.extend(self.model['lars']['vars'])
        #    try: part.remove(utils.SanitizeVariableName(self.target))
        #    except: pass
        
        #otherwise, go to the data structure itself
        else:
            part = container[model_part]
            
        return part


    def PredictValues(self, data_dictionary, **args):
        data = copy.copy(data_dictionary)
        data.pop(self.target)
        data_frame = utils.DictionaryToR(data)
        prediction_params = {'obj': self.model, 'newx': data_frame }
        
        prediction = r.Call(function='predict', **prediction_params).AsVector()
        prediction = array.array('d', prediction)

        return prediction
        
        
    def PredictExceedances(self, data_dictionary, **kwargs):
        prediction = self.PredictValues(data_dictionary)
        return array.array('l', [p > self.threshold for p in prediction])
        
        
    def PredictExceedanceProbability(self, data_dictionary, **kwargs):
        prediction = self.PredictValues(data_dictionary)
        se = self.Extract('RMSEP')
        nonexceedance_probability = r.Call(function='pnorm', q=array.array('d', [(self.threshold-p)/se for p in prediction])).AsVector()
        exceedance_probability = [float(1-item) for item in nonexceedance_probability]
        return exceedance_probability

        
    def Predict(self, data_dictionary, **kwargs):
        prediction = self.PredictValues(data_dictionary)
        return [float(item) for item in prediction]
        

    def Threshold(self, specificity=0.92):
        self.specificity = specificity
    
        if not hasattr(self, 'actual'):
            self.GetActual()
        
        if not hasattr(self, 'fitted'):
            self.GetFitted()

        #Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
        try:
            non_exceedances = [self.array_fitted[i] for i in range(len(self.actual)) if self.actual[i] <= self.regulatory_threshold]
            self.threshold = utils.Quantile(non_exceedances, specificity)
            self.specificity = float(sum([non_exceedances[i] for i in range(len(non_exceedances)) if non_exceedances[i] <= self.threshold])) / len(non_exceedances)

        #This error should only happen if somehow there are no non-exceedances in the training data.
        except ZeroDivisionError:
            self.threshold = self.regulatory_threshold        
            self.specificity = 1


    def GetActual(self):
        self.array_actual = array.array('d', self.model['actual'].AsVector())
        
        #Recover the actual counts by adding the residuals to the fitted counts.
        #residuals = np.array(self.model['residuals'].AsVector())
        #residuals = residual_values.transpose()
        
        #self.array_actual = np.array(fitted + residuals).squeeze()
        self.actual = list(self.array_actual)
        
        
    def GetFitted(self, **params):            
        fitted = array.array('d', self.model['fitted'].AsVector())
        
        self.array_fitted = fitted
        self.array_residual = array.array('d', [self.array_actual[i] - self.array_fitted[i] for i in range(len(fitted))])
        
        self.fitted = list(self.array_fitted)
        self.residual = list(self.array_residual)
        
        
    def GetInfluence(self):        
        #Get the covariate names
        self.names = self.data_dictionary.keys()
        self.names.remove(self.target)

        #Now get the model coefficients from R.
        coefficients = array.array('d', self.Extract('coef').AsVector())
        
        #Get the standard deviations (from the data_dictionary) and package the influence in a dictionary.
        raw_influence = list()
        
        for i in range(len(self.names)):
            standard_deviation = utils.std(self.data_dictionary[self.names[i]])
            raw_influence.append(float(abs(standard_deviation * coefficients[i+1])))
 
        self.influence = dict(zip([float(x/sum(raw_influence)) for x in raw_influence], self.names))
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
            if self.fitted[obs] > self.threshold:
                if self.actual[obs] > self.regulatory_threshold: t_pos += 1
                else: f_pos += 1
            else:
                if self.actual[obs] > self.regulatory_threshold: f_neg += 1
                else: t_neg += 1
        
        return [t_pos, t_neg, f_pos, f_neg]
        
        
    def Serialize(self):
        model_struct = dict()
        model_struct['model_type'] = 'spls'
        elements_to_save = ["data_dictionary", "threshold", "specificity", "target", "regulatory_threshold", "selectvars"]
        
        for element in elements_to_save:
            try: model_struct[element] = getattr(self, element)
            except KeyError: raise Exception('The required ' + element + ' was not found in the model to be serialized.')
            
        return model_struct
        
        
    def ToString(self):
        return "sPLS model"