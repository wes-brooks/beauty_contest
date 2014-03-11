adalasso_step <-
function(formula, data, family, weights, adaptive.object, s, verbose, adapt, selection.method) {
    result = list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    response.col = which(colnames(data)==response.name)
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,-response.col])
    
    m <- ncol(x)
    n <- nrow(x)

    if (adapt==TRUE) {
        result[['meanx']] = adaptive.object[['meanx']]
        result[['scale']] = adaptive.object[['adaweight']]
    } else {
        result[['meanx']] = sapply(predictor.names, function(x) return(0))
        result[['scale']] = sapply(predictor.names, function(x) return(1))
    }

    x.centered = sweep(x, 2, result[['meanx']], '-')
    x.scaled = sweep(x.centered, 2, result[['scale']], '*')
    
    #Binomial requires p, 1-p to both be specified:
    if (family=='binomial') {
        result[['model']] = model = glmnet(x=x.scaled, y=as.matrix(cbind(1-y, y), nrow(x), 2), family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)
    } else {
        result[['model']] = model = glmnet(x=x.scaled, y=y, family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)
    }
    
    if (!is.na(pmatch('cv', selection.method))) {
        #Binomial requires p, 1-p to both be specified:
        if (family=='binomial') {result[['cv']] = cv.glmnet(y=as.matrix(cbind(1-y, y), nrow(x), 2), x=x.scaled, nfolds=n, family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)}
        else {result[['cv']] = cv.glmnet(y=y, x=x.scaled, nfolds=n, family=family, weights=weights, lambda=s, standardize=FALSE, intercept=TRUE)}
        
        if (selection.method == 'cv.overshrink') {
            result[['lambda']] = result[['cv']][['lambda.1se']]
        } else {
            result[['lambda']] = result[['cv']][['lambda.min']]
        }
    } else if (selection.method == 'AICc') {
        dev = deviance(model)
        df = apply(predict(model, type='coefficients'), 2, function(x) sum(x != 0))
        AICc = dev + 2*df + 2*df*(df+1)/(n-df-1)
        result[['lambda.index']] = lambda.index = which.min(AICc)
        result[['lambda']] = model[['lambda']][lambda.index]
    }
    
    nonzero = predict(model, type='nonzero', s=result[['lambda']])
    if (verbose) {print(nonzero)}
    
    #Handle the case that the lasso selects no variables
    if (is.null(nonzero[[1]])) {
        indx = which(!sapply(predict(model, type='nonzero'), is.null))[1]
        result[['lambda']] = model[['lambda']][indx]
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
