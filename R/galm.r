require(galm)

GALM = new.env()

GALM$Model = list( 
    #represents a PLS model generated in R

    Create = function(self, ...) {
		args = list(...)
		
        #Check to see if a threshold has been specified in the function's arguments
        if ('regulatory_threshold' %in% names(args)) {
			self[['threshold']] = args[['regulatory_threshold']]
        } else {self[['threshold']] = 2.3711}   # if there is no 'threshold' key, then use the default (2.3711)
        self[['regulatory_threshold']] = self[['threshold']]

        self[['target']] = args[['target']]
        
        if ('population' %in% names(args)) {
			self[['population']] = args[['population']]
		} else {self[['population']] = 200}
        
        if ('generations' %in% names(args)) {
			self[['generations']] = args[['generations']]
        } else {self[['generations']] = 100}
        
        if ('mutate' %in% names(args)) {
			self[['mutate']] = args[['mutate']]
        } else {self[['mutate']] = 0.02}
        
        if ('ZOR' %in% names(args)) {
			self[['ZOR']] = args[['ZOR']]
        } else {self[['ZOR']] = 1}
        
        if ('verbose' %in% names(args)) {
			self[['verbose']] = args[['verbose']]
        } else {self[['verbose']] = FALSE}
        
        if ('specificity' %in% names(args)) {
			specificity = args[['specificity']]
        } else {specificity = 0.90}
        
        #Get the data into R
        self[['data']] = args[['data']]
        
        #Generate a GALM model in R.
        self[['formula']] = as.formula(paste(self[['target']], '~.', sep=''))
        params = list(
			'formula' = self[['formula']],
            'data' = self[['data']],
            'population' = self[['population']],
            'generations' = self[['generations']],
            'mutateRate' = self[['mutate']],
            'zeroOneRatio' = self[['ZOR']],
            'verbose' = self[['verbose']]
		)
        self[['model']] = do.call('galm', params)
                
        #Get some information out of the model
        self = self[['PostProcess']](self)
		
        #Establish a decision threshold
        self = self[['Threshold']](self, specificity)
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
        params = list(obj=self[['model']], newx=data)
        prediction = drop(do.call('predict', params))
    
        return(prediction)
	},
        

    Threshold = function(self, specificity=0.9) {
        self[['specificity']] = specificity
        
        if (!('fitted' %in% names(self))) {
            self = self[['PostProcess']](self)
		}

        #Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
        self = tryCatch ({
            nonexceedances = self[['fitted']][which(self[['actual']] < self[['regulatory_threshold']])]
            self[['threshold']] = as.numeric(quantile(nonexceedances, specificity))
            self[['specificity']] = sum(sapply(nonexceedances, function(x) {x < threshold})) / length(nonexceedances)
		},
		
        #This error should only happen if somehow there are no non-exceedances in the training data.
        error = function (e) {
			self[['threshold']] = self[['regulatory_threshold']]
		},
		finally = {
		    return(self)
		})
	},
	
	
	PostProcess = function(self, ...) {
        self[['actual']] = drop(self[['model']][['actual']])       
        self[['fitted']] = drop(self[['model']][['fitted']])
        self[['residual']] = self[['actual']] - self[['fitted']]
		
		self[['vars']] = self[['model']][['vars']]
     
		return(self)
	},
        
		
    GetInfluence = function(self) {
        #Get the covariate names
        self[['names']] = colnames(self[['data']])
        names = self[['names']] = self[['names']][self[['names']] != self[['target']]]

        #Now get the model coefficients from R.
        coefficients = drop(self[['model']][['coef']])
        
        #Get the standard deviations (from the data_dictionary) and package the influence in a dictionary.
        raw_influence = vector()
        
        for (i in 1:length(self[['names']])) {
            standard_deviation = sd(self[['data']][,self[['names']][i]])
            raw_influence = c(raw_influence, abs(standard_deviation * coefficients[i+1]))
		}
        influence = raw_influence / sum(raw_influence)
		
        self[['influence']] = Map(function(var) {influence[which(names==var)]}, names)
		
        return(self)	
	}            
)