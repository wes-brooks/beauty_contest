adalars_step <- function(formula, data, adaptive.object=NULL, overshrink=FALSE, adapt=FALSE) {
    result = list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    response.col = which(colnames(data)==response.name)
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,predictor.names])

    colnames(x) = predictor.names
    colnames(y) = response.name
    
    m <- ncol(x)
    n <- nrow(x)
    p.max = min(m-2, floor(n/2))
    
    if (adapt==TRUE) {
        result[['meanx']] = adaptive.object[['meanx']]
        result[['scale']] = adaptive.object[['adaweight']]
    } else {
        result[['meanx']] = sapply(predictor.names, function(x) return(0))
        result[['scale']] = sapply(predictor.names, function(x) return(1))
    }

    x.centered = sweep(x, 2, result[['meanx']], '-')
    x.scaled = sweep(x.centered, 2, result[['scale']], '*')
    
    result[['model']] = model = lars(x=x.scaled, y=y, type='lar', max.steps=p.max, normalize=FALSE)
    result[['cv']] = cv = cv.lars(y=y, x=x.scaled, type='lar', index=1:p.max, K=n, plot.it=FALSE, mode='step', normalize=FALSE)
  
    if (overshrink) {
        err.min = min(cv$cv)
        err.tol = err.min + cv$cv.error[which.min(cv$cv)]
        which.tol = which(cv$cv<err.tol)
        result[['lambda.index']] = lambda.index = max(min(which.tol, na.rm=TRUE), 2, na.rm=TRUE)
    } else {
        result[['lambda.index']] = lambda.index = max(which.min(cv$cv), 2, na.rm=TRUE)
    }
    
    result[['predictors']] = predictor.names
    result[['fitted']] = predict.lars(model, newx=x.scaled, type='fit', s=lambda.index, mode='step')$fit
    result[['residuals']] = y-result[['fitted']]
    result[['vars']] = names(which(model$beta[lambda.index,] != 0))   
    
    coefs = predict.lars(model, type='coefficients', s=lambda.index, mode='step')
    result[['coef']] = coefs$coefficients[which(coefs$coefficients!=0)]
    result[['MSEP']] = cv$cv[lambda.index]
    result[['RMSEP']] = sqrt(result[['MSEP']])
    result[['Intercept']] = predict(model, newx=matrix(0,1,m), type='fit', s=lambda.index, mode='step')$fit
    
    return(result)
}
