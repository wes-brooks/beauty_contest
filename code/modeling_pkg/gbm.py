import numpy as np
import random
import copy
import utils
import RDotNetWrapper as rdn

#Import the gbm library to R and import the R engine
rdn.r.EagerEvaluate("library(gbm)")
r = rdn.Wrap()


class Model(object): 
    '''represents a gbm (tree with boosting) model generated in R'''
    
    def __init__(self, **args):
        if "model_struct" in args: self.Deserialize( args['model_struct'] )
        else: self.Create(**args)
    
    
    def Deserialize(self, model_struct):
        '''Recreate a gbm model from a serialized object'''
    
        #Load saved parameters from the serialized object.
        self.regulatory_threshold = model_struct['regulatory_threshold']
        self.threshold = model_struct['threshold']
        self.iterations = model_struct['iterations']
        self.cost = model_struct['cost']
        self.specificity = self.cost[1]
        self.depth = model_struct['depth']
        self.shrinkage = model_struct['shrinkage']
        self.data_dictionary = model_struct['data_dictionary']
        self.target = model_struct['target']
        self.weights = model_struct['weights']        
        
        #Get the data into R 
        self.data_frame = utils.DictionaryToR(self.data_dictionary)

        #Generate a gbm model in R.
        self.formula = r.Call('as.formula', obj=self.target + '~.')
        self.gbm_params = {'formula' : self.formula, \
            'distribution' : 'bernoulli', \
            'data' : self.data_frame, \
            'weights' : self.weights, \
            'interaction.depth' : self.depth, \
            'shrinkage' : self.shrinkage, \
            'n.trees' : self.iterations }
        
        self.model=r.Call(function='gbm', **self.gbm_params).AsList()
    

    def Create(self, **args):
        '''Create a new gbm model object'''
    
        #Check to see if a threshold has been specified in the function's arguments
        try: self.regulatory_threshold = args['threshold']
        except KeyError: self.regulatory_threshold=2.3711   # if there is no 'threshold' key, then use the default (2.3711)
        self.threshold = 0   #decision threshold

        try: self.iterations = args['iterations']
        except KeyError: self.iterations=500   # if there is no 'iterations' key, then use the default (400)

        #Cost: two values - the first is the cost of a false positive, the second is the cost of a false negative.
        try: self.cost = args['cost']
        except KeyError: self.cost=[1,1]   # if there is no 'cost' key, then use the default [1,1] (=equal weight)
        self.specificity = self.cost[1]      

        #depth: how many branches should be allowed per decision tree?
        try: self.depth = args['depth']
        except KeyError: self.depth = 1   # if there is no 'depth' key, then use the default 1 (decision stumps)  

        #shrinkage: learning rate parameter
        try: self.shrinkage = args['shrinkage']
        except KeyError: self.shrinkage = 0.01   # if there is no 'shrinkage' key, then use the default 0.01

        #Store some object data
        self.data_dictionary = copy.deepcopy(args['data'])
        self.target = target = args['target']
                
        #Check to see if a weighting method has been specified in the function's arguments
        try:
            #integer (discrete) weighting
            if str(args['weights']).lower()[0] in ['d', 'i']: 
                self.weights = self.AssignWeights(method=1)
                
            #float (continuous) weighting
            elif str(args['weights']).lower()[0] in ['f']: 
                self.weights = self.AssignWeights(method=2)
                
            #cost-based weighting
            elif str(args['weights']).lower()[0] in ['c']: 
                self.weights = self.AssignWeights(method=3)

            #cost-based weighting, and down-weight the observations near the threshold
            elif str(args['weights']).lower()[0] in ['b']: 
                self.weights = self.AssignWeights(method=4)

            else: self.weights = self.AssignWeights(method=0) 
                
        #If there is no 'weights' key, set all weights to one.
        except KeyError: 
            self.weights = self.AssignWeights(method=0) 
        
        #Label the exceedances in the training set.
        self.data_dictionary[target] = self.Discretize(self.data_dictionary[target])
        
        #Get the data into R 
        self.data_frame = utils.DictionaryToR(self.data_dictionary)

        #Generate a gbm model in R.
        self.formula = r.Call('as.formula', obj=self.target + '~.')
        self.gbm_params = {'formula' : self.formula, \
            'distribution' : 'bernoulli', \
            'data' : self.data_frame, \
            'weights' : self.weights, \
            'interaction.depth' : self.depth, \
            'shrinkage' : self.shrinkage, \
            'n.trees' : self.iterations }
        
        self.model=r.Call(function='gbm', **self.gbm_params).AsList()


    def AssignWeights(self, method=0):
        '''Weight the observations in the training set based on their distance from the threshold.'''
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
                
                #Decide how many times to replicate each slice of data
                if i<=0:
                    replicates = 0
                else:
                    replicates = 2*i
                    
                weights[rows] = replicates + 1
                
        #Continuous weighting: weight is the observation's distance (in standard deviations) from the threshold.      
        elif method == 2:
            weights = abs(deviation)

        #put more weight on exceedances
        elif method == 3:
            #initialize all weights to one.
            weights = np.ones( len(deviation) )

            #apply weight to the exceedances
            rows = np.where( deviation > 0 )[0]
            weights[rows] = self.cost[1]

            #apply weight to the non-exceedances
            rows = np.where( deviation <= 0 )[0]
            weights[rows] = self.cost[0]

        #put more weight on exceedances AND downweight near the threshold
        elif method == 4:
            #initialize all weights to one.
            weights = np.ones( len(deviation) )

            #apply weight to the exceedances
            rows = np.where( deviation > 0 )[0]
            weights[rows] = self.cost[1]

            #apply weight to the non-exceedances
            rows = np.where( deviation <= 0 )[0]
            weights[rows] = self.cost[0]

            #downweight near the threshold
            rows = np.where( abs(deviation) <= 0.25 )[0]
            weights[rows] = weights[rows]/4.

        #No weights: all weights are one.
        else: weights = np.ones( len(deviation) )
            
        return weights
            

    def Discretize(self, raw):
        '''Label observations as above or below the threshold.'''
        #discretized = np.zeros(raw.shape[0], dtype=int)
        #discretized[ raw >= self.regulatory_threshold ] = 1
        #discretized[ raw < self.regulatory_threshold ] = -1
        discretized = np.array(raw >= self.regulatory_threshold, dtype=int)
        
        return discretized
        

    def Extract(self, model_part, **args):
        try: container = args['extract_from']
        except KeyError: container = self.model
        
        #use R's coef function to extract the model coefficients
        if model_part == 'coef':
            part = r.Call( function='coef', object=self.model, intercept=True )
        
        #otherwise, go to the data structure itself
        else:
            part = container.model_part
            
        return part


    def Predict(self, data_dictionary):
        data_frame = utils.Dictionary_to_RDotNet(data_dictionary)
        prediction_params = {'object': self.model, 'newdata': data_frame, 'n.trees': self.iterations }
        prediction = r.Call(function='predict', **prediction_params).AsVector()

        #Translate the R output to a type that can be navigated in Python
        prediction = np.array(prediction).squeeze()
        
        return list(prediction)
        

    def Validate(self, data_dictionary):
        predictions = self.Predict(data_dictionary)
        actual = data_dictionary[self.target]

        p = predictions

        raw = list()
    
        for k in range(len(predictions)):
            t_pos = int(predictions[k] >= self.threshold and actual[k] >= self.regulatory_threshold)
            t_neg = int(predictions[k] <  self.threshold and actual[k] < self.regulatory_threshold)
            f_pos = int(predictions[k] >= self.threshold and actual[k] < self.regulatory_threshold)
            f_neg = int(predictions[k] <  self.threshold and actual[k] >= self.regulatory_threshold)
            raw.append([t_pos, t_neg, f_pos, f_neg])
        
        raw = np.array(raw)
        
        return raw


    def Plot(self, **plotargs ):
        try:
            ncomp = plotargs['ncomp']
            if type(ncomp)==str: plotargs['ncomp']=self.ncomp
                
        except KeyError: pass
        
        r['''dev.new''']()
        r.plot(self.model, **plotargs)

        
    def Serialize(self):
        model_struct = dict()
        model_struct['model_type'] = 'gbm'
        elements_to_save = ["data_dictionary", "iterations", "threshold", "specificity", "target", "regulatory_threshold", "cost", "depth", "shrinkage", "weights"]
        
        for element in elements_to_save:
            try: model_struct[element] = getattr(self, element)
            except KeyError: raise Exception('The required ' + element + ' was not found in the model to be serialized.')
            
        return model_struct
