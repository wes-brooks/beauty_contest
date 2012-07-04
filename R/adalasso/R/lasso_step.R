lasso_step <-
function(y, x, family, weights, adaptive.object=NULL, s=NULL, verbose=FALSE, ...) {
    result = list()
    
    m <- ncol(x)
    n <- nrow(x)
    one <- rep(1, n)
    result[['meanx']] = meanx <- drop(one %*% x)/n
    x.centered <- scale(x, meanx, FALSE)         # first subtracts mean
    normx <- sqrt(drop(one %*% (x.centered^2)))
    names(normx) <- NULL
    xs = x.centered
    for (k in 1:dim(x.centered)[2]) {
        if (normx[k]!=0) {
            xs[,k] = xs[,k] / normx[k]
        } else {
            xs[,k] = rep(0, dim(xs)[1])
            normx[k] = Inf #This should allow the lambda-finding step to work.
        }
    }
    
    if (is.null(adaptive.object)) { 
        #Use the glmnet algorithm to fit the model
        result[['coef.scale']] = coef.scale = 1/normx
    } else {  
        ada.weight = adaptive.object[['adaweight']]                      # weights for adaptive lasso
        for (k in 1:dim(x.centered)[2]) {
            if (!is.na(ada.weight[k])) {
                xs[,k] = xs[,k] * ada.weight[k]
            } else {
                xs[,k] = rep(0, dim(xs)[1])
                ada.weight[k] = 0 #This should allow the lambda-finding step to work.
            }
        }
        result[['coef.scale']] = coef.scale = ada.weight/normx 
    }    
    
    result[['model']] = model = glmnet(x=xs, y=y, family=family, weights=weights, lambda=s, ...)
    
    result[['cv.model']] = cv.model = cv.glmnet(y=y, x=xs, nfolds=dim(x)[1], family=family, weights=weights, ...)
    result[['lambda']] = lambda = cv.model$lambda.min
    nonzero = as.vector(predict(model, type='nonzero', s=lambda))
    if (verbose) {print(nonzero)}
    
    #Handle the case that the lasso selects no variables
    if (is.null(nonzero[[1]])) {
        indx = min(which(result[['cv.model']][['nzero']]>0))
        result[['lambda']] = lambda = result[['cv.model']]$lambda[indx]
        nonzero = as.vector(predict(model, type='nonzero', s=lambda))    
        if (verbose) {print(paste("indx: ", indx, ", lambda: ", lambda, ", nonzero: ", nonzero, sep=''))}
    }
    
    coefs = coef(model, s=lambda)
    result[['coef']] = as.list(coefs)[nonzero+1]
    names(result[['coef']]) = rownames(coefs)[nonzero+1]
    result[['intercept']] = intercept = coefs[1]  
    result[['vars']] = names(result[['coef']])
    
    return(result)
}
