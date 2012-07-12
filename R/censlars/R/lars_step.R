lars_step <- function(y, x, adaptive.object=NULL) {
    result = list()
    
    m <- ncol(x)
    n <- nrow(x)
    p.max = min(m-1, floor(n/2))
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
    
    result[['model']] = model = lars(x=xs, y=y, type='lar', max.steps=p.max)
    result[['cv']] = cv.model = cv.lars(y=y, x=xs, type='lar', index=1:p.max, K=dim(x)[1], plot.it=FALSE, mode='step')
    
    err.min = min(cv.model$cv)
    err.tol = err.min + cv.model$cv.error[which.min(cv.model$cv)]
    which.tol = which(cv.model$cv<err.tol)
    result[['lambda.index']] = lambda.index = max(min(which.tol, na.rm=TRUE), 2, na.rm=TRUE)
        
    result[['fitted']] = predict.lars(model, newx=xs, type='fit', s=lambda.index, mode='step')$fit
    result[['residuals']] = y-result[['fitted']]
    result[['vars']] = vars = names(which(abs(model$beta[lambda.index,])>0))
    print(paste(vars, collapse=", "))
    coefs = predict.lars(model, type='coefficients', s=lambda.index, mode='step')
    result[['coefs']] = coefs$coefficients[which(coefs$coefficients>0)]
    result[['MSEP']] = cv.model$cv[lambda.index]
    result[['RMSEP']] = sqrt(result[['MSEP']])
    result[['Intercept']] = predict(model, newx=matrix(0,1,dim(x)[2]), type='fit', s=lambda.index, mode='step')$fit
    
    return(result)
}
