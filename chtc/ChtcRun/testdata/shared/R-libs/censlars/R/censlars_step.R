censlars_step <- function(formula, data, adaptive.object=NULL, overshrink=FALSE, adapt=FALSE) {
    result = list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    response.col = which(names(data)==response.name)
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    #Get the initial lasso estimate
    if (!is.null(adaptive.object)) {
        y = as.matrix(adaptive.object[['latent']])
    } else {
        y = as.matrix(data[,response.col])
    }
    x = as.matrix(data[,-response.col])
    
    m <- ncol(x)
    n <- nrow(x)
    p.max = min(m-1, floor(n/2))
    
    #Set up the lists to hold the adaptive elements:
    result[['meanx']] = list()
    result[['coef.scale']] = list()
    xs = x
    
    for (predictor in predictor.names) {
        #Center the appropriate column of the design matrix
        k = which(names(data)[-which(names(data)==response.name)] == predictor)
        
        if (adapt==TRUE) {
            #First, center this column of the design matrix
            result[['meanx']][[predictor]] = mean(data[[predictor]])
            xs[,k] = xs[,k] - result[['meanx']][[predictor]]      
            
            #Now scale it for unit norm
            result[['normx']][[predictor]] <- sqrt(sum(xs[,k]^2))

            if (result[['normx']][[predictor]] == 0) {
                result[['normx']][[predictor]] = Inf #This should allow the lambda-finding step to work.
            }
            
            if (is.null(adaptive.object)) { 
                result[['coef.scale']][[predictor]] = 1 / result[['normx']][[predictor]]
            } else {      
                if (is.na(adaptive.object[['adaweight']][[predictor]])) {                    
                    adaptive.object[['adaweight']][[predictor]] = 0 
                }
                result[['coef.scale']][[predictor]] = adaptive.object[['adaweight']][[predictor]] / result[['normx']][[predictor]]
            }
            xs[,k] = xs[,k] * result[['coef.scale']][[predictor]]   
        } else {
            result[['meanx']][[predictor]] = 0
            result[['coef.scale']][[predictor]] = 1
        }
    }
    
    result[['model']] = model = lars(x=xs, y=y, type='lar', max.steps=p.max)
    result[['cv']] = cv = cv.lars(y=y, x=xs, type='lar', index=1:p.max, K=n, plot.it=FALSE, mode='step')
    
    if (overshrink) {
        err.min = min(cv$cv)
        err.tol = err.min + cv$cv.error[which.min(cv$cv)]
        which.tol = which(cv$cv<err.tol)
        result[['lambda.index']] = lambda.index = max(min(which.tol, na.rm=TRUE), 2, na.rm=TRUE)
    } else {
        result[['lambda.index']] = lambda.index = max(which.min(cv$cv), 2, na.rm=TRUE)
    }
    
    result[['fitted']] = predict.lars(model, newx=xs, type='fit', s=lambda.index, mode='step')$fit
    result[['residuals']] = y-result[['fitted']]
    result[['vars']] = names(which(abs(model$beta[lambda.index,])>0))
    coefs = predict.lars(model, type='coefficients', s=lambda.index, mode='step')
    result[['coefs']] = coefs$coefficients[which(coefs$coefficients>0)]
    result[['MSEP']] = cv$cv[lambda.index]
    result[['RMSEP']] = sqrt(result[['MSEP']])
    result[['Intercept']] = predict(model, newx=matrix(0,1,dim(x)[2]), type='fit', s=lambda.index, mode='step')$fit
    
    return(result)
}
