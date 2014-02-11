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
        } else {
            result[['meanx']][[predictor]] = 0
            result[['coef.scale']][[predictor]] = 1
        }
		xs[,predictor] = xs[,predictor] * result[['coef.scale']][[predictor]]
    }
    
    if (family=='binomial') {
        print("family is binomial")
        result[['model']] = glmnet(x=xs, y=as.matrix(cbind(1-y, y), nrow(x), 2), family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)
        result[['cv']] = cv.glmnet(y=as.matrix(cbind(1-y, y), nrow(x), 2), x=xs, nfolds=n, family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)
    } else {
        result[['model']] = glmnet(x=xs, y=y, family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)
        result[['cv']] = cv.glmnet(y=y, x=xs, nfolds=n, family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)
    }
    
    if (overshrink==TRUE) {
        result[['lambda']] = result[['cv']][['lambda.1se']]
    } else {
        result[['lambda']] = result[['cv']][['lambda.min']]
    }
    
    nonzero = predict(result[['model']], type='nonzero', s=result[['lambda']])
    if (verbose) {print(nonzero)}
    
    #Handle the case that the lasso selects no variables
    if (is.null(nonzero[[1]])) {
        indx = min(which(result[['cv']][['nzero']]>0), na.rm=TRUE)
        result[['lambda']] = result[['cv']][['lambda']][indx]
        nonzero = predict(result[['model']], type='nonzero', s=result[['lambda']])
    }
    if (verbose) {print(paste("lambda: ", result[['lambda']], ", nonzero: ", paste(nonzero, collapse=","), sep=''))}
	nonzero = as.vector(t(nonzero))
    
    coefs = coef(result[['model']], s=result[['lambda']])
	coefnames = rownames(coefs)
	coefs = as.vector(coefs)

    result[['coef']] = as.list(coefs[nonzero+1])
    names(result[['coef']]) = coefnames[nonzero+1]
    result[['intercept']] = intercept = coefs[1]
    result[['vars']] = coefnames[nonzero+1]
    
    return(result)
}
