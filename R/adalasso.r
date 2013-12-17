require(glmnet)
require(adalasso, lib.loc="R-libs")

LAL = new.env()

LAL$Model = list( 
    #represents an adaptive lasso model generated in R

    Create = function(self, ...) {
        #Create an adaptive lasso model object
		args = list(...)
	
        #Check to see if a threshold has been specified in the function's arguments
        if ('regulatory_threshold' %in% names(args)) {
			self[['regulatory_threshold']] = args[['regulatory_threshold']]
        } else {self[['regulatory_threshold']] = 2.3711}   # if there is no 'threshold' key, then use the default (2.3711)
        
        #Check to see if a specificity has been specified in the function's arguments
        if ('specificity' %in% names(args)) {
			self[['specificity']] = args[['specificity']]
        } else {self[['specificity']] = 0.9}

        if ('adapt' %in% names(args)) {
			self[['adapt']] = args[['adapt']]
        } else {self[['adapt']] = FALSE}
        
        if ('selectvars' %in% names(args)) {
			self[['selectvars']] = args[['selectvars']]
        } else {self[['selectvars']] = FALSE}

        if ('overshrink' %in% names(args)) {
			self[['overshrink']] = args[['overshrink']]
        } else {self[['overshrink']] = FALSE}  

        if ('verbose' %in% names(args)) {
			self[['verbose']] = args[['verbose']]
        } else {self[['verbose']] = FALSE}  		
        
        #Get the data into R
        self[['data']] = data = args[['data']]
        self[['target']] = target = args[['target']]
        self[['nobs']] = nrow(data)
                
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
                        
        #Generate a logistic regression model in R.
        self[['formula']] = as.formula(paste(self[['target']], '~.', sep=''))
        params = list(
			'formula' = self[['formula']],
            'family' = 'binomial',
            'data' = self[['data']],
            'weights' = self[['weights']],
            'verbose' = self[['verbose']],
            'adapt' = self[['adapt']],
            'overshrink' = self[['overshrink']],
            'selectvars' = self[['selectvars']]
		)
        self[['model']] = do.call('adalasso', params)
        
        #Select model components and a decision threshold
        self = self[['PostProcess']](self)
        self = self[['Threshold']](self, self[['specificity']])
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
    

    Extract = function(self, model_part, ...) {
		args = list(...)
		
        if ('extract_from' %in% names(args)) {
			container = args[['extract_from']]
        } else {container = self[['model']]}
        
        #use R's coef function to extract the model coefficients
        if (model_part == 'coef') {
            part = coef(self[['model']], intercept=True)
        
        #otherwise, go to the data structure itself
        } else {
            part = container[[model_part]]
		}
            
        return(part)
	},


    Predict = function(self, data) {
        params = list('obj'=self[['model']], 'newx'=data)
        prediction = drop(do.call("predict.adalasso", params))

        return(prediction)
	},
	

	PostProcess = function(self, ...) {
        self[['residual']] = drop(self[['model']][['residuals']])       
        self[['fitted']] = drop(self[['model']][['fitted.values']])
        self[['actual']] = self[['fitted']] + self[['residual']]
		
		self[['vars']] = self[['model']][['lasso']][['vars']]
     
		return(self)
	}
)
