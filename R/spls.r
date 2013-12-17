require(spls)
require(spls.wrap, lib.loc="R-libs")

SPLS = new.env()

SPLS$Model = list( 
    #represents an sPLS model generated in R

    Create = function(self, ...) {
		args = list(...)
		
        #Check to see if a threshold has been specified in the function's arguments
        if ('regulatory_threshold' %in% names(args)) {
			self[['threshold']] = args[['regulatory_threshold']]
        } else {self[['threshold']] = 2.3711}   # if there is no 'threshold' key, then use the default (2.3711)
        self[['regulatory_threshold']] = self[['threshold']]

        self[['target']] = args[['target']]
        
        if ('selectvars' %in% names(args)) {
			self[['selectvars']] = args[['selectvars']]
        } else {self[['selectvars']] = FALSE}
        
        if ('specificity' %in% names(args)) {
			specificity = args[['specificity']]
        } else {specificity = 0.90}
        
        #Get the data into R
        self[['data']] = data = args[['data']]
        
        #Generate a PLS model in R.
        self[['formula']] = as.formula(paste(self[['target']], '~.', sep=''))
        params = list(
			'formula' = self[['formula']],
            'data' = self[['data']],
            'selectvars' = self[['selectvars']]
		)
        self[['model']] = do.call('spls.wrap', params)
        
        #Get some information out of the model
        self = self[['PostProcess']](self)
        
        #Establish a decision threshold
        self = self[['Threshold']](self, specificity)
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
	

    Extract = function(self, model_part) {
		args = list(...)
		
        if ('extract_from' %in% names(args)) {
			container = args[['extract_from']]
        } else {container = self[['model']]}

		part = container[[model_part]]
            
        return(part)
	},


    Predict = function(self, data, ...) {
        params = list('obj'=self[['model']], 'newx'=data)
        prediction = drop(do.call('predict', params))

        return(prediction)
	},
	

	PostProcess = function(self, ...) {
        self[['actual']] = drop(self[['model']][['actual']])       
        self[['fitted']] = drop(self[['model']][['fitted']])
        self[['residual']] = self[['actual']] - self[['fitted']]
		
		self[['vars']] = drop(self[['model']][['vars']])
     
		return(self)
	}
)