require(pls)

#Define the GBM environment
PLS <- new.env()

PLS$Model = list( 
    #represents a pls model generated in R'''
	
    Create = function(self, ...) {
print("entered Create")
        #Create a new pls model object
		args <- list(...)
print("got args")
        #Check to see if a threshold has been specified in the function's arguments
        if ('threshold' %in% names(args)) {
			self[['regulatory_threshold']] = args[['threshold']]
        } else { self[['regulatory_threshold']] = 2.3711}   # if there is no 'threshold' key, then use the default (2.3711)
        self[['threshold']] = 0   #decision threshold
print("A")
        #specificity: If provided, used to set the decision threshold
        if ('specificity' %in% names(args)) {
			self[['specificity']] = args[['specificity']]
        } else { self[['specificity']] = 0.9 }  # if there is no 'specificity' key, then use the default 0.9  
print("B")
        #Store some object data
        self[['data']] = data = args[['data']]
        self[['target']] = target = args[['target']]
        self[['actual']] = data[,target]
print("C")        
		if (ncol(data) > 2) {
			validation = 'LOO'
		} else {
			validation = 'none'
		}
print("going to modeling")		
		#Generate a pls model in R.
        self[['formula']] = as.formula(obj=paste(self[['target']], '~.', sep=''))
        pls_params = list(
			formula = self[['formula']],
            data = self[['data']],
            validation = validation,
			x = TRUE
        )
        self[['model']] = do.call(plsr, pls_params)
print("made model")
        #Get the number of columns from the validation step
        #(Might be fewer than the number of predictor variables if n<p)
        if (ncol(data) > 2) {
			self[['ncomp_max']] = dim(x=self[['model']][['validation']][['pred']])[3]
		} else {
			self[['ncomp_max']] = 1
		}
print("now to get actual")		
		#Use cross-validation to find the best number of components in the model.
        self <- self[['GetActual']](self)	
        if (ncol(data) > 2) {
			self <- self[['CrossValidation']](self, args)
        } else {
			self[['ncomp']] = 1
		}
        self <- self[['GetFitted']](self)
print("going to thresholding")        
        #Establish a decision threshold
        self <- self[['Threshold']](self, self[['specificity']])
        self[['vars']] = colnames(self[['data']])
        self[['vars']] = self[['vars']][self[['vars']] != self[['target']]]
print("returning from model create")
        return(self)
	},

		
	CrossValidation = function(self, ...) {
		args = list(...)
		
		if ('cv_method' %in% names(args)) {
			cv_method = args[['cv_method']]
		} else { cv_method = 0}
		
        #Select ncomp by the requested CV method
        validation = self[['model']][['validation']]
        
        #method 0: select the fewest components with PRESS within 1 stdev of the least PRESS (by the bootstrap)
        if (cv_method == 0) { #Use the bootstrap to find the standard deviation of the MSEP
            #Get the leave-one-out CV error from R:
            columns = self[['ncomp_max']] #min(self[['num_predictors']], self[['ncomp_max']])
            cv = drop(validation[['pred']])
            rows = dim(cv)[1]
           
            truth = matrix(rep(self[['actual']], columns), nrow=rows, ncol=columns)
			err = truth - cv
			PRESS = colSums(err**2)
			ncomp = which.min(PRESS)[1]
            cv_squared_error = (cv[,ncomp] - self[['actual']])**2
            
			PRESS_stdev = vector()
            for (i in 1:100) {
                PRESS_bootstrap = vector()
                
                for (j in 1:100) {
                    PRESS_bootstrap = c(PRESS_bootstrap, sum(sample(cv_squared_error, replace=TRUE)))
				}                    
                PRESS_stdev = c(PRESS_stdev, sd(PRESS_bootstrap))
			}
            med_stdev = median(PRESS_stdev)
            
            #Maximum allowable PRESS is the minimum plus one standard deviation
            self[['ncomp']] = which(PRESS < min(PRESS) + med_stdev)[1]
            
        #method 1: select the fewest components w/ PRESS less than the minimum plus a 4% of the range
        } else if (cv_method==1) {
            #PRESS stands for predicted error sum of squares
            PRESS0 = validation[['PRESS0']][1]
            PRESS = validation[['PRESS']]
    
            #the range is the difference between the greatest and least PRESS values
            PRESS_range = abs(PRESS0 - min(PRESS))
            
            #Maximum allowable PRESS is the minimum plus a fraction of the range.
			#choose the most parsimonious model that satisfies that criterion
            max_CV_error = min(PRESS) + PRESS_range/25
            self[['ncomp']] = which(PRESS < max_CV_error)[1]
		}
		
		return(self)
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
        prediction_params = list(object=self[['model']], newdata=data, ncomp=self[['ncomp']])
        prediction = drop(do.call(predict, prediction_params))
    
        return(prediction)
	},
                
		
    GetActual = function(self) {
        #Get the fitted counts from the model.
        columns = min(self[['num_predictors']], self[['ncomp_max']])
        fitted = drop(self[['model']][['fitted.values']])
        rows = nrow(fitted)
 
        #Recover the actual counts by adding the residuals to the fitted counts.
        residuals = drop(self[['model']][['residuals']])

        self[['actual']] = as.vector(as.matrix(fitted + residuals)[,1])
	
		return(self)
	},
        
        
    GetFitted = function(self, ...) {
		args = list(...)
        		
		if ('ncomp' %in% names(args)) {
			ncomp = args[['ncomp']]
		} else if ('ncomp' %in% names(self)) {
			ncomp = self[['ncomp']]
		} else {
            ncomp = 1
		}
		
        #Get the fitted counts from the model so we can compare them to the actual counts.
        cols = min(self[['num_predictors']], self[['ncomp_max']])
        fitted = drop(self[['model']][['fitted.values']])
        rows = nrow(fitted)
        
        self[['fitted']] = fitted[,self[['ncomp']]]
        self[['residual']] = self[['actual']] - self[['fitted']]
     
		return(self)
	},
        
		
    GetInfluence = function(self) {
        #Get the covariate names
        self[['names']] = colnames(self[['data']])
        names = self[['names']] = self[['names']][self[['names']] != self[['target']]]

        #Now get the model coefficients from R.
        coefficients = coef(self[['model']], self[['ncomp']])
        
        #Get the standard deviations (from the data_dictionary) and package the influence in a dictionary.
        raw_influence = vector()
        
        for (i in 1:length(self[['names']])) {
            standard_deviation = sd(self[['data']][,self[['names']][i]])
            raw_influence = c(raw_influence, abs(standard_deviation * coefficients[i+1]))
		}
        influence = raw_influence / sum(raw_influence)
		
        self[['influence']] = Map(function(var) {influence[which(names==var)]}, names)
		
        return(self)	
	},

    
    Threshold = function(self, specificity=0.9) {
        self[['specificity']] = specificity
        
        if (!('fitted' %in% names(self))) {
            self = self[['GetFitted']](self)
		}

        #Decision threshold is the [specificity] quantile of the fitted values for non-exceedances in the training set.
        self = tryCatch ({
            non_exceedances = self[['fitted']][which(self[['actual']] < self[['regulatory_threshold']])]
            self[['threshold']] = as.numeric(quantile(non_exceedances, specificity))
            self[['specificity']] = sum(sapply(non_exceedances, function(x) {x < threshold})) / length(non_exceedances)
		},
		
        #This error should only happen if somehow there are no non-exceedances in the training data.
        error = function (e) {
			self[['threshold']] = self[['regulatory_threshold']]
		},
		finally = {
		    return(self)
		})
	}
)