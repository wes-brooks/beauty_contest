require(lars)
require(adalars)

AL = new.env()

AL$Model = list(
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
        
        if ('selectonly' %in% names(args)) {
			self[['selectonly']] = args[['selectonly']]
        } else {self[['selectonly']] = FALSE}

        if ('overshrink' %in% names(args)) {
			self[['overshrink']] = args[['overshrink']]
        } else {self[['overshrink']] = FALSE} 		
        
        #Get the data into R
        self[['data']] = data = args[['data']]
        self[['target']] = target = args[['target']]
        self[['nobs']] = nrow(data)
		
		#Generate a logistic regression model in R.
        self[['formula']] = as.formula(paste(self[['target']], '~.', sep=''))
        params = list(
			'formula' = self[['formula']],
            'data' = self[['data']],
            'adapt' = self[['adapt']],
            'overshrink' = self[['overshrink']],
            'selectonly' = self[['selectonly']]
		)
        self[['model']] = do.call('adalars', params)
		
        #Select model components and a decision threshold
        self = self[['PostProcess']](self)
        self = self[['Threshold']](self, self[['specificity']])

		return(self)
	},
	
	
	Extract = function(self, model_part, ...) {
		args = list(...)
		
        if ('extract_from' %in% names(args)) {
			container = args[['extract_from']]
        } else {container = self[['model']]}
        
        #use R's coef function to extract the model coefficients
        if (model_part == 'coef') {
			step = self[['model']][['lars']][['lambda.index']][1]
			part = as.vector(coef(object=self[['model']][['lars']][['model']], mode='step', s=step))
        
		#use R's MSEP function to estimate the variance.
        } else if (model_part == 'MSEP') {
            part = self[['model']][['lars']][['MSEP']]
         
        #use R's RMSEP function to estimate the standard error.
        } else if (model_part == 'RMSEP') {
            part = self[['model']][['lars']][['RMSEP']]
			
		#Get the variable names, ordered as R sees them.
        } else if (model_part == 'names') {
            part = c("Intercept")
            part = c(part, self[['model']][['lars']][['vars']])
            part = part[part != self[['target']]]
		
        #otherwise, go to the data structure itself
        } else {
            part = container[[model_part]]
		}
            
        return(part)
	},
	

    Predict = function(self, data) {
        params = list('obj'=self[['model']], 'newx'=data)
        prediction = do.call("predict.adalars", params)
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
		
		self[['vars']] = self[['model']][['lars']][['vars']]
		self[['coefs']] = self[['model']][['lars']][['coefs']]
     
		return(self)
	}
)
