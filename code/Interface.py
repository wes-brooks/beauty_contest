'''
Created on May 27, 2011
@author: wrbrooks
'''
#Import the PLS modeling classes
import sys
import clr

#Set the separators 
_names = sys.builtin_module_names
if 'nt' in _names:
    sep = '\\'
    pathsep = ';'
else:
    sep = '/'
    pathsep = ':'

#Set the paths to IronPython based on the current working directory
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython 2.7', 'Lib', 'site-packages']))
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython 2.7', 'DLLs']))
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython 2.7', 'Lib']))
sys.path.insert(0, sep.join(['..', 'bin', 'IronPython 2.7']))
sys.path.insert(0, sep.join(['..', 'bin']))

#We must link to the IronPython libraries before we can load the os module.
clr.AddReference("IronPython")
clr.AddReference("IronPython.Modules")
import os
import copy

#For some reason, numpy is unable to find the mtrand library on its own.
cwd = os.getcwd()
root = sep.join(cwd.split(sep)[:-1])
sys.path[4] = root + sep + sep.join(['bin', 'IronPython 2.7', 'Lib', 'site-packages'])
sys.path[3] = root + sep + sep.join(['bin', 'IronPython 2.7', 'DLLs'])
sys.path[2] = root + sep + sep.join(['bin', 'IronPython 2.7', 'Lib'])
sys.path[1] = root + sep + sep.join(['bin', 'IronPython 2.7'])
sys.path[0] = root + sep + sep.join(['bin'])
#print sys.path
clr.AddReference("mtrand.dll")
clr.AddReference("System.Data")
#clr.AddReference("RDotNetExtensions-1.5.0")

import System
import pickle

#Set the R_HOME environment variable
#os.environ["R_HOME"] = cwd + sep + sep.join(['bin', 'R-2.15.1'])

import utils
import BeachController as Control

class BeachInterface(object):

    def __init__(self):
        self.u = utils

    def Validate(self, data, target, method, specificity='', **args):
        '''This is the main function in the script. It uses the PLS modeling classes to build a predictive model.'''
        
        #parse the inputs
        target = str(target)
        args['specificity'] = specificity
        
        #initialize the objects where we will drop the results
        result_list = list()
        combined = summary = []
        columns = ['specificity', 'true pos', 'true neg', 'false pos', 'false neg', 'total']
        
        #parse the modeling method and then call it
        return Control.Validate(data, target, method, **args)
        

    def SpecificityChart(self, validation_results):
        '''Just relay this call directly to the Controller.'''
        return Control.SpecificityChart(validation_results)
    

    def GetPossibleSpecificities(self, model):   
        '''Find out what values specificity could take if we count out one non-exceedance at a time.'''
        regulatory_threshold = model.regulatory_threshold
        thresholds = sorted([model.fitted[i] for i in range(len(model.fitted)) if model.actual[i] <= regulatory_threshold])
        specificities = [x/float(len(thresholds)) for x in range(len(thresholds))]
        return [[float(x) for x in thresholds], list(specificities)]
        
        
    def Serialize(self, model):
        '''Convert the model to a string that can be written to disk.'''
        model_struct = model.Serialize()
        serialized = pickle.dumps(model_struct, protocol=2)
        return serialized
        
        
    def Deserialize(self, model_string):
        '''Take a string and turn it into a model object.'''
        model_struct = pickle.loads(model_string)
        model = Control.Deserialize(model_struct)
        return model

    
    def GetPredictors(self, model):
        '''Return a list of the predictor variables that are used in this model.'''
        predictors = model.data_dictionary.keys()
        predictors.remove( model.target )
        return predictors
        
        
    def GetModelExpression(self, model):
        '''Return a list of the predictor variables that are used in this model.'''
        predictors = model.data_dictionary.keys()
        predictors.remove( model.target )
        
        expression = predictors[0]
        for predictor in predictors[1:]:
            expression = expression + " + " + predictor
        
        return expression
        
    
    def Predict(self, model, data):
        '''Use the model to predict the value that its output will take over the observations in the data.'''
        [headers, data] = utils.DotNetToArray(data)
        data_dict = dict( zip(headers, [array.array('d', [row[i] for row in data]) for i in range(len(data[0]))]) )
        predictions = model.Predict(data_dict)
        return predictions
        
        
    def ProbabilityOfExceedance(self, prediction, threshold, se):
        return utils.ProbabilityOfExceedance(prediction, threshold, se)
        #exceedance_probability = 1-norm.cdf(x=prediction, loc=threshold, scale=se)
        #return double(exceedance_probability.squeeze())
            
    
Interface = BeachInterface()

