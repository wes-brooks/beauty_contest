adalasso_step <-
function(formula, data, family, weights, adaptive.object=NULL, s=NULL, verbose=FALSE, adapt=FALSE, overshrink=FALSE) {
    result = list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    response.col = which(colnames(data)==response.name)
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,-response.col])
    
    m <- ncol(x)
    n <- nrow(x)
    
    #Set up the lists to hold the adaptive elements:
    result[['meanx']] = list()
    result[['coef.scale']] = list()
    xs = x
    
    for (predictor in predictor.names) {
        if (adapt==TRUE) {
            #We will center each column of this matrix:
            result[['meanx']][[predictor]] = mean(data[,predictor])
            xs[,predictor] = xs[,predictor] - result[['meanx']][[predictor]]
            
            #Scale the column for unit norm
            result[['normx']][[predictor]] <- sqrt(sum(xs[,predictor]**2))
            
            if (result[['normx']][[predictor]] == 0) {
                result[['normx']][[predictor]] = Inf #This should allow the lambda-finding step to work.
            }
                
            if (is.null(adaptive.object)) { 
                result[['coef.scale']][[predictor]] = 1 / result[['normx']][[predictor]]
            } else {  
                if (is.na(adaptive.object[['adaweight']][[predictor]])) {
                    adaptive.object[['adaweight']][[predictor]] = 0 #This should allow the lambda-finding step to work.
                }
                result[['coef.scale']][[predictor]] = adaptive.object[['adaweight']][[predictor]] / result[['normx']][[predictor]]
            }
            xs[,predictor] = xs[,predictor] * result[['coef.scale']][[predictor]]
        } else {
            result[['meanx']][[predictor]] = 0
            result[['coef.scale']][[predictor]] = 1
        }
    }
    
    if (family=='binomial') {
        print("family is binomial")
        result[['model']] = model = glmnet(x=xs, y=as.matrix(cbind(y, 1-y), nrow(x), 2), family=family, weights=weights, lambda=s)
        result[['cv']] = cv.model = cv.glmnet(y=as.matrix(cbind(y, 1-y), nrow(x), 2), x=xs, nfolds=n, family=family, weights=weights, lambda=s)
    } else {
        result[['model']] = model = glmnet(x=xs, y=y, family=family, weights=weights, lambda=s)
        result[['cv']] = cv.model = cv.glmnet(y=y, x=xs, nfolds=n, family=family, weights=weights, lambda=s)
    }
    
    if (overshrink==TRUE) {
        result[['lambda']] = lambda = cv.model$lambda.1se
    } else {
        result[['lambda']] = lambda = cv.model$lambda.min
    }
    
    nonzero = as.vector(predict(model, type='nonzero', s=lambda))
    if (verbose) {print(nonzero)}
    
    #Handle the case that the lasso selects no variables
    if (is.null(nonzero[[1]])) {
        indx = min(which(result[['cv']][['nzero']]>0), na.rm=TRUE)
        result[['lambda']] = lambda = result[['cv']]$lambda[indx]
        nonzero = as.vector(predict(model, type='nonzero', s=lambda))    
    }
    if (verbose) {print(paste("lambda: ", lambda, ", nonzero: ", paste(nonzero, collapse=","), sep=''))}
    
    coefs = coef(model, s=lambda)
    result[['coef']] = as.list(coefs)[nonzero+1]
    names(result[['coef']]) = rownames(coefs)[nonzero+1]
    result[['intercept']] = intercept = coefs[1]  
    result[['vars']] = names(result[['coef']])
    
    return(result)
}
