library(gbm)

#Define the GBM environment
GBM <- new.env()

GBM$Model = list( 
    #represents a gbm (tree with boosting) model generated in R'''

    Create = function(self, ...) {
        #Create a new gbm model object
    
		args <- list(...)

        #Check to see if a threshold has been specified in the function's arguments
        if ('threshold' %in% names(args)) {self[['regulatory_threshold']] = args[['threshold']]
        } else { self[['regulatory_threshold']] = 2.3711}   # if there is no 'threshold' key, then use the default (2.3711)
        self[['threshold']] = 0   #decision threshold

        if ('threshold' %in% names(args)) {self[['iterations']] = args[['iterations']]
        } else { self[['iterations']] = 10000}   # if there is no 'iterations' key, then use the default (2000)

        #Cost: two values - the first is the cost of a false positive, the second is the cost of a false negative.
        if ('cost' %in% names(args)) {self[['cost']] = args[['cost']]
        } else {self[['cost']] = c(1,1)}   # if there is no 'cost' key, then use the default [1,1] (=equal weight)
     
        #specificity: If provided, used to set the decision threshold
        if ('specificity' %in% names(args)) { self[['specificity']] = args[['specificity']]
        } else { self[['specificity']] = 0.9 }  # if there is no 'specificity' key, then use the default 0.9  

        #depth: how many branches should be allowed per decision tree?
        if ('depth' %in% names(args)) { self[['depth']] = args[['depth']]
        } else { self[['depth']] = 5 }  # if there is no 'depth' key, then use the default 1 (decision stumps)  
       
        #n.minobsinnode: what is the fewest observations per node in the tree?
        if ('minobsinnode' %in% names(args)) {self[['minobsinnode']] = args[['minobsinnode']]
        } else {self[['minobsinnode']] = 5}

        #shrinkage: learning rate parameter
        if ('shrinkage' %in% names(args)) { self[['shrinkage']] = args[['shrinkage']]
        } else { self[['shrinkage']] = 0.001 }  # if there is no 'shrinkage' key, then use the default 0.01
       
        #bagging fraction: proportion of data used at each step
        if ('fraction' %in% names(args)) { self[['fraction']] = args[['fraction']]
        } else { self[['fraction']] = 0.5 }   # if there is no 'fraction' key, then use the default 0.5
       
        #shrinkage: learning rate parameter
        if ('gbm.folds' %in% names(args)) { self[['folds']] = args[['gbm.folds']]
        } else { self[['folds']] = 5 }   # if there is no 'folds' key, then use the default 5-fold CV

        #Store some object data
        self[['data']] = data = args[['data']]
        self[['target']] = target = args[['target']]
        self[['actual']] = data[,target]
               
        #Check to see if a weighting method has been specified in the function's arguments
        if ('weights' %in% names(args)) {
            #integer (discrete) weighting
            if (substring(tolower(args['weights']),1,1) %in% c('d', 'i')) { 
                self[['weights']] = self[['AssignWeights']](self=self, method=1)
                
            #float (continuous) weighting
            } else if (substring(tolower(args[['weights']]),1,1) %in% c('f')) {
                self[['weights']] = self[['AssignWeights']](self=self, method=2)
                
            #cost-based weighting
            } else if (substring(tolower(args[['weights']]),1,1) %in% c('c')) { 
                self[['weights']] = self[['AssignWeights']](self=self, method=3)

            #cost-based weighting, and down-weight the observations near the threshold
            } else if (substring(tolower(args[['weights']]),1,1) %in% c('b')) { 
                self[['weights']] = self[['AssignWeights']](self=self, method=4)

            } else {self[['weights']] = self[['AssignWeights']](self=self, method=0) }
		} else {
            #If there is no 'weights' key, set all weights to one.
            self[['weights']] = self[['AssignWeights']](self=self, method=0) 
		}
    
        #Label the exceedances in the training set.
        #self.data_dictionary[target] = self.Discretize(self.data_dictionary[target])

        #Generate a gbm model in R.
        self[['formula']] = as.formula(obj=paste(self[['target']], '~.', sep=''))
        self[['gbm_params']] = list(formula = self[['formula']],
            data = self[['data']],
            distribution = 'gaussian',            
            weights = self[['weights']],
            interaction.depth = self[['depth']],
            shrinkage = self[['shrinkage']],
            n.trees = self[['iterations']],
            bag.fraction = self[['fraction']],
            n.minobsinnode = self[['minobsinnode']],
            cv.folds = self[['folds']]
        )
        self[['model']] = do.call(gbm, self[['gbm_params']])

        #Find the best number of iterations for predictive performance. Prefer to use CV.
        perf_params = list(object=self[['model']], plot.it=FALSE)
        if (self[['folds']] > 1) {
			perf_params[['method']] = 'cv'
        } else { perf_params[['method']] = 'OOB' }
        
        self[['trees']] = tryCatch({
			do.call(gbm.perf, perf_params)[1]
		},
		error = {
			self[['iterations']]
		})
     
        self <- self[['GetFitted']](self)
        self[['Threshold']](self, self[['specificity']])
        self[['vars']] = colnames(self[['data']])
        self[['vars']] = self[['vars']][self[['vars']] != self[['target']]]

        return(self)
	},

	
    AssignWeights = function(self, method=0) {
        #Weight the observations in the training set based on their distance from the threshold.
        std = sd(self[['actual']])
        deviation = sapply(self[['actual']], function(x) {(x-self[['regulatory_threshold']])/std})
        
        #Integer weighting: weight is the observation's rounded-up whole number of standard deviations from the threshold.
        if (method == 1) {
            weights = rep(1, length(deviation))
            breaks = floor(min(deviation)):ceiling(max(deviation))
			
            for (i in breaks) {
                #Find all the observations that meet both criteria simultaneously
                rows = which(deviation >= i & deviation < i+1)
                
                #Decide how many times to replicate each slice of data
                if (i<=0) {
                    replicates = 0
                } else {
                    replicates = 2*i
				}
                    
                weights[rows] = replicates + 1
			}
                
        #Continuous weighting: weight is the observation's distance (in standard deviations) from the threshold.      
        } else if (method == 2) {
            weights = abs(deviation)

        #put more weight on exceedances
        } else if (method == 3) {
            #initialize all weights to one.
            weights = rep(1, length(deviation))

            #apply weight to the exceedances
            rows = which(deviation > 0)
            weights[rows] = self[['cost']][2]

            #apply weight to the non-exceedances
            rows = which(deviation <= 0)
            weights[rows] = self[['cost']][1]

        #put more weight on exceedances AND downweight near the threshold
        } else if (method == 4) {
            #initialize all weights to one.
            weights = rep(1, length(deviation))

            #apply weight to the exceedances
            rows = which(deviation > 0)
            weights[rows] = self[['cost']][2]

            #apply weight to the non-exceedances
            rows = which(deviation <= 0)
            weights[rows] = self[['cost']][1]

            #downweight near the threshold
            rows = which(abs(deviation[i]) <= 0.25)
            weights[rows] = weights[rows]/4
			
        #No weights: all weights are one.
        } else {weights = rep(1, length(deviation))}
            
        return(weights)
    },
	

    Discretize = function(self, raw) {
        #Label observations as above or below the threshold.
        discretized = sapply(1:length(raw), function(x) {if (x >= self[['regulatory_threshold']]) {1} else {0}})
        
        return(discretized)
	},
        

    Extract = function(self, model_part, ...) {
		args = list(...)
		
        if ('extract_from' %in% names(args)) {
			container = args[['extract_from']]
        } else { container = self[['model']] }
        
        #use R's coef function to extract the model coefficients
        if (model_part == 'coef') { 
            part = coef(object=self[['model']], intercept=TRUE)
        
        #otherwise, go to the data structure itself
        } else {
            part = container[['model_part']]
		}
            
        return(part)
	},


    Predict = function(self, data, ...) {
        prediction_params = list(object=self[['model']], newdata=data, n.trees=self[['trees']])
        prediction = do.call(predict, prediction_params)
        
        return(prediction)
	},
        

    #Validate = function(self, data) {
    #    predictions = self[['Predict']](data_dictionary)
    #    actual = data[,self[['target']]]
    #    p = predictions
    #    raw = matrix(NA,0,4)
	#	
    #    for (k in 1:length(predictions)) {
    #        t_pos = int(predictions[k] >= self[['threshold']] and actual[k] >= self[['regulatory_threshold']])
    #        t_neg = int(predictions[k] <  self[['threshold']] and actual[k] < self[['regulatory_threshold']])
    #        f_pos = int(predictions[k] >= self[['threshold']] and actual[k] < self[['regulatory_threshold']])
    #        f_neg = int(predictions[k] <  self[['threshold']] and actual[k] >= self[['regulatory_threshold']])
    #        raw = rbind(raw, c(t_pos, t_neg, f_pos, f_neg]))
	#	}
    #    
    #    return(raw)
	#},
        
        
    GetFitted = function(self, ...) {
        self[['fitted']] = predict(object=self[['model']], n.trees=self[['trees']], newdata=self[['data']], ...)
        self[['residual']] = self[['residuals']] = self[['actual']] - self[['fitted']]

        return(self)
	},
        
		
    GetInfluence = function(self) {
        self[['names']] = colnames(self[['data']]) 
        self[['names']] = self[['names']][self[['names']] != self[['target']]]
        
        summary = summary.gbm(object=self[['model']], plotit=FALSE)
        indx = summary[0]

        influence = summary[1]
        vars = levels(x=indx)
        
        #Create a dictionary with all the influences and a list of those variables with influence greater than 1%.
        self[['influence']] = names(self[['names']]) = influence
        self[['vars']] = vars[which(influence[k]>5)]

        return(self)
	},

    
    Threshold = function(self, specificity=0.9) {
        self[['specificity']] = specificity
        
        if (!('fitted' %in% names(self))) {
            self[['GetFitted']](self)
		}

        #Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
        self[['threshold']] = tryCatch ({
            non_exceedances = self[['fitted']][which(self[['actual']] < self[['regulatory_threshold']])]
            self[['threshold']] = quantile(non_exceedances, specificity)
            self[['specificity']] = sum(sapply(non_exceedances, function(x) {x < self[['threshold']]})) / length(non_exceedances)
		},
		
        #This error should only happen if somehow there are no non-exceedances in the training data.
        error = {
			self[['threshold']] = self[['regulatory_threshold']]
		})

        return(self)
	}
)