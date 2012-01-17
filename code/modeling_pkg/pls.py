import numpy as np
import random
import copy
from random import choice
import utils
import RDotNetWrapper as rdn

#Import the pls library into R, and connect python to R.
rdn.r.EagerEvaluate("library(pls)") 
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
        
        #Get the data into R 
        self.data_frame = utils.DictionaryToR(self.data_dictionary)
        self.data_dictionary = copy.deepcopy(self.data_dictionary)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a PLS model in R.
        self.formula = r.Call('as.formula', obj=self.target + '~.')
        self.pls_params = {'formula' : self.formula, \
            'data' : self.data_frame, \
            'validation' : 'LOO', \
            'x' : True }
        self.model = r.Call(function='plsr', **self.pls_params).AsList()

        #Use cross-validation to find the best number of components in the model.
        self.GetActual()
        self.ncomp = model_struct['ncomp']
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
        if 'AR_part' in args: self.AR_part = args['AR_part']
        if 'specificity' in args: specificity=args['specificity']
        else: specificity=0.9
        
        #Get the data into R
        data = args['data']
        self.data_frame = utils.DictionaryToR(data)
        self.data_dictionary = copy.deepcopy(data)
        self.predictors = len(self.data_dictionary.keys()) - 1
        
        #Generate a PLS model in R.
        self.formula = r.Call('as.formula', obj=self.target + '~.')
        self.pls_params = {'formula' : self.formula, \
            'data' : self.data_frame, \
            'validation' : 'LOO', \
            'x' : True }
        self.model = r.Call(function='plsr', **self.pls_params).AsList()

        #Use cross-validation to find the best number of components in the model.
        self.GetActual()
        self.CrossValidation(**args)
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
            #part = list( r.Call(function='MSEP', object=self.model).AsVector() )
            part = sum((self.array_fitted-self.array_actual)**2)/self.array_fitted.shape[0]
            #part = part['val'].AsVector()[self.ncomp]
            
        #use R's RMSEP function to estimate the standard error.
        elif model_part == 'RMSEP':
            part = (sum((self.array_fitted-self.array_actual)**2)/self.array_fitted.shape[0])**(0.5)
            #part = part['val'].AsVector()[self.ncomp]
            #part = list( r.Call(function='RMSEP', object=self.model).AsList() )
        
        #Get the variable names, ordered as R sees them.
        elif model_part == 'names':
            part = ["Intercept"]
            part.extend( self.data_frame.ColumnNames )
            try: part.remove(self.target)
            except: pass
        
        #otherwise, go to the data structure itself
        else:
            part = container[model_part]
            
        return part


    def PredictValues(self, data_dictionary, **args):
        data_frame = utils.DictionaryToR(data_dictionary)
        prediction_params = {'object': self.model, 'newdata': data_frame }
        
        prediction = r.Call(function='predict', **prediction_params).AsVector()
        
        #Reshape the vector of predictions
        columns = self.predictors
        prediction = np.array( prediction )
        rows = len(prediction) / columns
        prediction.shape = (columns, rows)
        prediction = prediction.transpose()

        return prediction
        
        
    def PredictExceedances(self, data_dictionary):
        prediction = self.PredictValues(data_dictionary)
        return np.array(prediction[:,self.ncomp-1] >= self.threshold, dtype=int)
        
        
    def PredictExceedanceProbability(self, data_dictionary):
        prediction = self.PredictValues(data_dictionary)[:,self.ncomp-1]
        se = self.Extract('RMSEP')
        exceedance_probability = 1-r.Call(function='pnorm', q=self.threshold-prediction/se)
        return list(exceedance_probability)

        
    def Predict(self, data_dictionary):
        prediction = self.PredictValues(data_dictionary)
        return list(prediction[:,self.ncomp-1].squeeze())
        
        
    def CrossValidation(self, cv_method=0, **args):
        '''Select ncomp by the requested CV method'''
        validation = self.model['validation'].AsDataFrame()
       
        #method 0: select the fewest components with PRESS within 1 stdev of the least PRESS (by the bootstrap)
        if cv_method == 0: #Use the bootstrap to find the standard deviation of the MSEP
            #Get the leave-one-out CV error from R:
            columns = self.predictors
            cv = np.array( validation['pred'].AsVector() )
            rows = len(cv) / columns
            cv.shape = (columns, rows)
            cv = cv.transpose()
            
            PRESS = map(lambda x: sum((cv[:,x]-self.array_actual)**2), range(cv.shape[1]))
            ncomp = np.argmin(PRESS)
            
            cv_squared_error = (cv[:,ncomp]-self.array_actual)**2
            sample_space = xrange(cv.shape[0])
            
            PRESS_stdev = list()
            
            #Cache random number generator and int's constructor for a speed boost
            _random, _int = random.random, int
            
            for i in np.arange(100):
                PRESS_bootstrap = list()
                
                for j in np.arange(100):
                    PRESS_bootstrap.append( sum([cv_squared_error[_int(_random()*cv.shape[0])] for i in sample_space]) )
                    
                PRESS_stdev.append( np.std(PRESS_bootstrap) )
                
            med_stdev = np.median(PRESS_stdev)
            
            #Maximum allowable PRESS is the minimum plus one standard deviation
            #good_ncomp = mlab.find( PRESS < min(PRESS) + med_stdev )
            good_ncomp = np.where( PRESS < min(PRESS) + med_stdev )[0]
            self.ncomp = int( min(good_ncomp)+1 )
            
        #method 1: select the fewest components w/ PRESS less than the minimum plus a 4% of the range
        if cv_method==1:
            #PRESS stands for predicted error sum of squares
            PRESS0 = validation['PRESS0'][0]
            PRESS = list( validation['PRESS'] )
    
            #the range is the difference between the greatest and least PRESS values
            PRESS_range = abs(PRESS0 - np.min(PRESS))
            
            #Maximum allowable PRESS is the minimum plus a fraction of the range.
            max_CV_error = np.min(PRESS) + PRESS_range/25
            #good_ncomp = mlab.find(PRESS < max_CV_error)
            good_ncomp = np.where(PRESS < max_CV_error)[0]
    
            #choose the most parsimonious model that satisfies that criterion
            self.ncomp = int( min(good_ncomp)+1 )
        

    def Threshold(self, specificity=0.92):
        self.specificity = specificity
    
        if not hasattr(self, 'actual'):
            self.GetActual()
        
        if not hasattr(self, 'fitted'):
            self.GetFitted()

        #Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
        try:
            non_exceedances = self.array_fitted[np.where(self.array_actual < 2.3711)[0]]
            self.threshold = utils.Quantile(non_exceedances, specificity)
            self.specificity = float(sum(non_exceedances < self.threshold))/non_exceedances.shape[0]

        #This error should only happen if somehow there are no non-exceedances in the training data.
        except IndexError: self.threshold = 2.3711


    def Validate(self, validation_dict):
        target = self.target
        ncomp = self.ncomp - 1
        regulatory = self.regulatory_threshold
    
        print "calling self.Predict from pls.Model.Validate"
        predictions = self.Predict_Values(validation_dict)
        predictions = predictions[:, ncomp]
        actual = validation_dict[target]
    
        raw = list()
    
        for k in range(len(predictions)):
            t_pos = int(predictions[k] >= self.threshold and actual[k] >= regulatory)
            t_neg = int(predictions[k] < self.threshold and actual[k] < regulatory)
            f_pos = int(predictions[k] >= self.threshold and actual[k] < regulatory)
            f_neg = int(predictions[k] < self.threshold and actual[k] >= regulatory)
            raw.append([t_pos, t_neg, f_pos, f_neg])
        
        raw = np.array(raw)
        return raw


    def GetActual(self):
        #Get the fitted counts from the model.
        columns = self.predictors
        fitted_values = np.array( self.model['fitted.values'].AsVector() )
        rows = len(fitted_values) / columns
        fitted_values.shape = (columns, rows)
        fitted_values = fitted_values.transpose()[:,0]
        
        #If this is the second stage of an AR model, then incorporate the AR predictions.
        if hasattr(self, 'AR_part'):
            mask = np.ones( self.AR_part.shape[0], dtype=bool )
            #nan_rows = mlab.find( np.isnan(self.AR_part[:,0]) )
            #nan_rows = np.where( np.isnan(self.AR_part[:,0]) )[0]
            
            mask[ nan_rows ] = False
            fitted_values += self.AR_part[mask,0]

        #Recover the actual counts by adding the residuals to the fitted counts.
        residual_values = np.array( self.model['residuals'].AsVector() )
        residual_values.shape = (columns, rows)
        residual_values = residual_values.transpose()[:,0]
        
        self.array_actual = np.array( fitted_values + residual_values ).squeeze()
        self.actual = list(self.array_actual)
        
        
    def GetFitted(self, **params):
        try: ncomp = params['ncomp']
        except KeyError:
            try: ncomp = self.ncomp
            except AttributeError: ncomp=1
            
        #Get the fitted counts from the model so we can compare them to the actual counts.
        columns = self.predictors
        fitted_values = np.array( self.model['fitted.values'].AsVector() )
        rows = len(fitted_values) / columns
        fitted_values.shape = (columns, rows)
        fitted_values = fitted_values.transpose()[:,self.ncomp-1]
        
        #If this is the second stage of an AR model, then incorporate the AR predictions.
        if hasattr(self, 'AR_part'):
            mask = np.ones( self.AR_part.shape[0], dtype=bool )
            #nan_rows = mlab.find( np.isnan(self.AR_part[:,0]) )
            nan_rows = np.where( np.isnan(self.AR_part[:,0]) )[0]
            mask[ nan_rows ] = False
            fitted_values += self.AR_part[mask,0]
        
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
        model_struct['model_type'] = 'pls'
        elements_to_save = ["data_dictionary", "ncomp", "threshold", "specificity", "target", "regulatory_threshold"]
        
        for element in elements_to_save:
            try: model_struct[element] = getattr(self, element)
            except KeyError: raise Exception('The required ' + element + ' was not found in the model to be serialized.')
            
        return model_struct
        
        
    def ToString(self):
        return "PLS model"
        
        


class Model_Wrapper(object):
    '''Contains several models that, together, cover the possible prediction space'''

    def __init__(self, data, target, **args):
        self.target = target
        self.model_frame = copy.deepcopy(data)
        self.model_data = np.array(data.values()).transpose()
        self.headers = data.keys()
        if 'AR_part' in args: self.AR_part = copy.copy(args['AR_part'])



    def Split(self, wedge=None, breakpoint=None, **args):
        finished = False
        i=0
        self.models = list()
        self.wedge = wedge
        self.breakpoint = breakpoint

        #Decide how many submodels we're making.
        if breakpoint is None:
            breaks=0
        else:
            breakpoint = np.array( np.sort(breakpoint), ndmin=1 )
            breaks = len(breakpoint) 
    
        #Make the submodels
        while not finished:
            if i>0: lower_bound = breakpoint[i-1]
            else: lower_bound = -np.infty
            if i<breaks:
                upper_bound = breakpoint[i]
            else:
                upper_bound = np.infty
                finished = True

            #Find which rows of data lie in this division.
            upper_rows = np.where( self.model_data[:,self.headers.index(wedge)] > lower_bound )[0]
            lower_rows = np.where( self.model_data[:,self.headers.index(wedge)] <= upper_bound )[0]

            #Now create a data dictionary with the data for this division.
            rows = filter( lambda x: x in upper_rows, lower_rows )
            submodel_data = self.model_data[rows,:]
            submodel_frame = dict(zip(self.headers, np.transpose(submodel_data)))
            if hasattr(self, 'AR_part'):
                args['AR_part'] = self.AR_part[rows,:]
                

            #Generate this submodel and add it to the list.
            self.f = submodel_frame
            submodel = Model(data=submodel_frame, target=self.target, **args)
            self.models.append(submodel)
            i+=1



    def Generate_Models(self, specificity=0.9, breakpoint='', breaks=0, balance_method=1, wedge='julian', **args):
        self.specificity = specificity
        self.wedge = wedge

        #Default is not to tune the split date. This will be overridden if the breakpoint is not specified.
        tune = False

        if not breakpoint:
            wedge_values = np.unique( self.model_frame[wedge] )
            med = np.median(wedge_values)
            breakpoint = med
            tune = True
        else: pass

        if breaks>0:
            self.Split(wedge, breakpoint, **args)
            self.Assign_Thresholds(**args)
            
            if tune:
                self.Tune_Split(balance_method=balance_method, **args)
            
        else:
            self.Split(wedge, **args)
            self.Assign_Thresholds(**args)
            
        self.Get_Actual()



    def Tune_Split(self, balance_method=1, **args):
        self.imbalance = list()
        possible_breaks = np.unique( self.model_frame[self.wedge] )
        
        #Sweep through the possible break points and find the imbalance at each
        for breakpoint in possible_breaks[10:-10]:
            self.Split(wedge=self.wedge, breakpoint = breakpoint, **args)
            self.Assign_Thresholds(**args)
            
            self.imbalance.append( [self.breakpoint, self.Imbalance(method=balance_method)] )
                
        
        #select the break point with the minimal imbalance
        self.imbalance = np.array(self.imbalance)
        optimal_split = np.argmin( self.imbalance[:,1] )
        breakpoint = self.imbalance[optimal_split,0]
        
        #split on the optimal break point and refit the model.
        self.Split(wedge=self.wedge, breakpoint=self.breakpoint)
        self.Assign_Thresholds(**args)
        
    
    
    def Assign_Thresholds(self, **args):
        #Assign the decision thresholds
        
        try: method=args['threshold_method']
        except KeyError: method=1
        
        try: self.specificity=args['specificity']
        except KeyError: pass
        
        if method == 0: self.Threshold_on_Proportions()
        elif method == 1: self.Threshold_on_Counts()
            
        
        
    def Threshold_on_Counts(self):
        counts = list()
        fitted_sorted = list()
        submodels = range( len(self.models) )
        winner = 0 #Begin with the first submodel

        for model in self.models:
            #Count the number of data points in the model and sort the fitted values.
            t_pos = 0.
            f_pos = 0.
            [f_neg, t_neg] = self.Initial_Counts(model)
            fit_order = list( np.argsort(model.array_fitted) )

            counts.append([t_pos, t_neg, f_pos, f_neg])      
            fitted_sorted.append(fit_order)

        counts = np.array(counts)
        [sensitivity, specificity] = self.Combined_Accuracy(counts)
        specificity_limit = self.specificity

        #Descend through the fitted counts to find the best decision threshold.
        while(specificity > specificity_limit):
            try:

                index = fitted_sorted[winner].pop()
                self.models[winner].threshold = self.models[winner].fitted[index]

                if (self.models[winner].actual[index] >= 2.3711): #A hit: continue to play the 'winner'
                    counts[winner,0] += 1. #t_pos
                    counts[winner,3] -= 1. #f_neg

                if (self.models[winner].actual[index] < 2.3711): #A miss: find a new 'winner'
                    counts[winner,2] += 1. #f_pos
                    counts[winner,1] -= 1. #t_neg

                    #Select a new 'winner', then repair the list of submodels.
                    last = winner
                    submodels.remove(last)
                    try: winner = choice( submodels )
                    except IndexError: winner=last
                    submodels.append(last)

                #Update the combined sensitivity, specificity.     
                [sensitivity, specificity] = self.Combined_Accuracy(counts)
            
            except IndexError:
                submodels.remove(winner)
                winner = choice( submodels )

        self.thresholding_counts = counts


    def Threshold_on_Proportions(self):
        counts = list()
        submodels = range( len(self.models) )

        for model in self.models:
            #Set the threshold of each submodel using the overall specificity limit.
            model.Threshold( self.specificity )

            counts.append(model.Count())

        counts = np.array(counts)
        self.thresholding_counts = counts


    def Initial_Counts(self, model):
        f_neg = 0.
        t_neg = 0.

        #Count the true number of exceedances, non-exceedances. Stored in the model.
        for k in range(len(model.fitted)):
            if (model.actual[k] >= 2.3711): f_neg += 1
            if (model.actual[k] < 2.3711): t_neg += 1

        return [f_neg, t_neg]



    def Combined_Accuracy(self, counts):
        t_pos = np.sum(counts[:,0])
        t_neg = np.sum(counts[:,1])
        f_pos = np.sum(counts[:,2])
        f_neg = np.sum(counts[:,3])

        try:
            specificity = t_neg/(t_neg + f_pos)
        except ZeroDivisionError:
            specificity = 0.

        try:
            sensitivity = t_pos/(t_pos + f_neg)
        except ZeroDivisionError:
            sensitivity = 1.

        return [sensitivity, specificity]



    def Imbalance(self, method=1):
        submodels = len(self.models)
        SS_model = 0
        SS_tot = 0
        errors = 0
        
        for i in range(submodels):
            if method == 0 : SS_tot += self.thresholding_counts[i,3]**2
            elif method == 1 : SS_tot += ( float(self.thresholding_counts[i,3]) / sum(self.thresholding_counts[i,:]))**2
            elif method == 2 : SS_tot += ( float(self.thresholding_counts[i,3]) / (self.thresholding_counts[i,0] + self.thresholding_counts[i,3]))**2
            
            if method == 0 : SS_model += self.thresholding_counts[i,3]
            elif method == 1 : SS_model += float(self.thresholding_counts[i,3]) / sum(self.thresholding_counts[i,:])
            elif method == 2 : SS_model += float(self.thresholding_counts[i,3]) / (self.thresholding_counts[i,0] + self.thresholding_counts[i,3])
            
            errors += self.thresholding_counts[i,2] + self.thresholding_counts[i,3]

        if method == 3 : return errors
        
        else:        
            SS_model = (SS_model**2)/submodels
            return SS_tot - SS_model
        
    
    def Predict(self, validation_frame):
        finished = False
        predictions = list()
        i=0

        validation_array = np.array(validation_frame.values()).transpose()
        validation_headers = validation_frame.keys()
    
        #Decide how many submodels we're making.
        if self.breakpoint is None:
            breaks=0
        else:
            self.breakpoint = np.array( np.sort(self.breakpoint), ndmin=1 )
            breaks = len(self.breakpoint) 
    
        #Make the submodels
        while not finished:
            if i>0: lower_bound = self.breakpoint[i-1]
            else: lower_bound = -np.infty

            if i<breaks:
                upper_bound = self.breakpoint[i]
            else:
                upper_bound = np.infty
                finished = True

            #Find which rows of data lie in this division.
            upper_rows = np.where( validation_array[:,validation_headers.index(self.wedge)] > lower_bound )[0]
            lower_rows = np.where( validation_array[:,validation_headers.index(self.wedge)] <= upper_bound )[0]

            #Now create a data dictionary with the data for this division.
            rows = filter( lambda x: x in upper_rows, lower_rows )
            submodel_data = validation_array[rows,:]
            submodel_frame = dict(zip(validation_headers, np.transpose(submodel_data)))

            #Make predictions on the split models  
            subseason_predictions = self.models[i].Predict(submodel_frame)[:, self.models[i].ncomp-1 ]
            predictions.extend(subseason_predictions)
            
            #Next submodel
            i += 1
            
        predictions = np.array(predictions).squeeze()
        return predictions
    
    
    
    
    def Validate(self, validation_frame, **args):
        finished = False
        self.predictions = list()
        self.prediction_residuals = list()
        i=0
        raw = list()
        validation_array = np.array(validation_frame.values()).transpose()
        validation_headers = validation_frame.keys()
           
        #Decide how many submodels we're making.
        if self.breakpoint is None:
            breaks=0
        else:
            self.breakpoint = np.array( np.sort(self.breakpoint), ndmin=1 )
            breaks = len(self.breakpoint)
    
        #Make the submodels
        while not finished:
            if i>0: lower_bound = self.breakpoint[i-1]
            else: lower_bound = -np.infty

            if i<breaks:
                upper_bound = self.breakpoint[i]
            else:
                upper_bound = np.infty
                finished = True

            #Find which rows of data lie in this division.
            upper_rows = np.where( validation_array[:,validation_headers.index(self.wedge)] > lower_bound )[0]
            lower_rows = np.where( validation_array[:,validation_headers.index(self.wedge)] <= upper_bound )[0]

            #Now create a data dictionary with the data for this division.
            rows = filter( lambda x: x in upper_rows, lower_rows )

            #If this CV fold has nothing on one side of the split, then return a row of zeros
            if len(rows)>0:
                submodel_data = validation_array[rows,:]
                submodel_frame = dict(zip(validation_headers, np.transpose(submodel_data)))
                #if hasattr(args, 'AR_part'): args['AR_part'] = AR_part[rows]
    
                #Make predictions on the split models  
                predictions = self.models[i].Predict(submodel_frame)[:, self.models[i].ncomp-1 ]
                if 'AR_part' in args:
                    predictions += args['AR_part'][rows]
                
                actual = submodel_frame[self.target]
                self.actual = actual
                self.i = i
                self.predictions.extend(predictions)
                residuals = actual - predictions
                self.prediction_residuals.extend(residuals)
                
                for k in range(len(predictions)):
                    self.k = k
                    t_pos = int(predictions[k] >= self.models[i].threshold and actual[k] >= 2.3711)
                    t_neg = int(predictions[k] <  self.models[i].threshold and actual[k] < 2.3711)
                    f_pos = int(predictions[k] >= self.models[i].threshold and actual[k] < 2.3711)
                    f_neg = int(predictions[k] <  self.models[i].threshold and actual[k] >= 2.3711)
                    raw.append([t_pos, t_neg, f_pos, f_neg])
            else:
                pass

            i+=1

        raw = np.array(raw)
        return raw
        
        
    def Get_Actual(self):
        self.actual = list()
        self.fitted = list()
        self.residual = list()
        
        for m in self.models:
            self.actual.extend(m.actual)
            self.fitted.extend(m.fitted)
            self.residual.extend(m.residual)
            
            

    def Plot(self, **plotargs):
        for model in self.models:
            model.Plot(**plotargs)
            