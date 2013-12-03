require(devtools)
install("R-libs/galogistic")
require(galogistic)

GALogistic = new.env()

GALogistic$Model = list( 
    #represents a PLS model generated in R

    Create = function(self, ...) {
		args = list(...)
		
        #Check to see if a threshold has been specified in the function's arguments
        if ('regulatory_threshold' %in% names(args)) {
			self[['threshold']] = args[['regulatory_threshold']]
        } else {self[['threshold']] = 2.3711}   # if there is no 'threshold' key, then use the default (2.3711)
        self[['regulatory_threshold']] = self[['threshold']]

        self[['target']] = target = args[['target']]
        
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
		
		#Check to see if a weighting method has been specified in the function's arguments
        if ('weights' %in% names(args)) {
            #integer (discrete) weighting
            if (tolower(substring(args[['weights']],1,1)) %in% c('d', 'i')) {
                self[['weights']] = self[['AssignWeights']](self, method=1)
                
            #float (continuous) weighting
            } else if (tolower(substring(args[['weights']],1,1)) %in% c('c', 'f')) {
                self[['weights']] = self[['AssignWeights']](self, method=2)
                
            } else {self[['weights']] = self[['AssignWeights']](self, method=0)}
                
        #If there is no 'weights' key, set all weights to one.
        } else { 
            self[['weights']] = self[['AssignWeights']](self, method=0) 
		}
        
        #Label the exceedances in the training set.
        self[['data']][[target]] = self[['AssignLabels']](self, self[['data']][[target]])
		
        #Generate a GALogistic model in R.
        self[['formula']] = as.formula(paste(self[['target']], '~.', sep=''))
        params = list(
			'formula' = self[['formula']],
            'data' = self[['data']],
			'family' = 'binomial',
			'weights' = self[['weights']],
            'population' = self[['population']],
            'generations' = self[['generations']],
            'mutateRate' = self[['mutate']],
            'zeroOneRatio' = self[['ZOR']],
            'verbose' = self[['verbose']]
		)
        self[['model']] = do.call('galogistic', params)
                
        #Get some information out of the model
        self = self[['PostProcess']](self)
		
        #Establish a decision threshold
        self = self[['Threshold']](self, specificity)
	},
	
	
	AssignLabels = function(self, raw) {
        #Label observations as above or below the threshold.
        raw = sapply(raw, function(x) {x > self[['regulatory_threshold']]})
        return(raw)
	},
	
	
	AssignWeights = function(self, method=0) {
		obs = self[['data']][[self[['target']]]]
	
        #Weight the observations in the training set based on their distance from the threshold.
        std = sd(obs)
        deviation = sapply(obs, function(x) {(x-self[['regulatory_threshold']])/std})
        
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
        prediction = drop(do.call('predict.galogistic', params))
    
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
