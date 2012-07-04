lars_step <-
function(y, x) {
    result = list()
    
    p.max = min(dim(x)[2]-1, floor(dim(x)[1]/2))
    print(paste('p.max=', p.max, sep=''))
    print(paste('dim(x)=', paste(dim(x), collapse=", "), sep=''))
    result[['cv']] = cv.model = cv.lars(y=y, x=x, type='lar', index=1:p.max, K=min(5, dim(x)[1]), plot.it=FALSE, mode='step')
    err.min = min(cv.model$cv)
    err.tol = err.min + cv.model$cv.error[which.min(cv.model$cv)]
    print(paste('which.min=', which.min(cv.model$cv), sep=''))
    print(paste('err.min=', err.min, sep=''))
    print(paste('err.tol=', err.tol, sep=''))
    which.tol = which(cv.model$cv<err.tol)
    print(paste('which.tol=', paste(which.tol, collapse=", "), sep=''))
    
    #result[['lambda.index']] = lambda.index = max(2, which.min(cv.model$cv))
    result[['lambda.index']] = lambda.index = max(min(which.tol, na.rm=TRUE), 2, na.rm=TRUE)
    print(paste('lambda.index=', lambda.index, sep=''))
    result[['model']] = model = lars(y=y, x=x, type='lar', max.steps=p.max)
    result[['fitted']] = predict.lars(model, newx=x, type='fit', s=lambda.index, mode='step')$fit
    result[['residuals']] = y-result[['fitted']]
    result[['vars']] = vars = names(which(abs(model$beta[lambda.index,])>0))
    coefs = predict.lars(model, type='coefficients', s=lambda.index, mode='step')
    result[['coefs']] = coefs$coefficients[which(coefs$coefficients>0)]
    result[['MSEP']] = cv.model$cv[lambda.index]
    result[['RMSEP']] = sqrt(result[['MSEP']])
    result[['Intercept']] = predict(model, newx=matrix(0,1,dim(x)[2]), type='fit', s=lambda.index, mode='step')$fit
    
    return(result)
}

