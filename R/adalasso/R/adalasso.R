adalasso <-
function(formula, data, family, weights, max.iter=20, tol=1e-25, s=NULL, verbose=FALSE, ...) {
    #Create the object that will hold the output
    result = list()
    class(result) = "adalasso"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    model.data = data
    na.rows = (which(is.na(model.data))-1) %% dim(model.data)[1] + 1
    if (length(na.rows)>0)
        model.data = model.data[-na.rows,]

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(names(model.data)==response.name)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
        
    f = as.formula(paste(paste(response.name, "~", sep=''), paste(predictor.names, collapse='+'), sep=''))#, env=as.environment(model.data))
    result[['adapt']] = adapt = initial_step(formula=f, data=model.data, family=family, weights=weights, verbose=verbose, ...)    
    
    #Get the initial lasso estimate
    y = as.matrix(model.data[,response.col])
    x = as.matrix(model.data[,-response.col])
    result[['lasso']] = lasso_step(y=y, x=x, family=family, weights=weights, s=s, verbose=verbose, adaptive.object=adapt, ...)
    
    #prepare for iteration
    iter = 1
    change = tol+1
    lambda.former = result[['lasso']][['lambda']]
    result[['lambda']] = c(lambda.former)
    
    #Repeat until convergence
    while (iter<=max.iter && change>tol) {
        if (verbose) {cat(paste("Iteration: ", iter, "\n", sep=""))}
        f = as.formula(paste(paste(response.name, "~", sep=''), paste(result[['lasso']][['vars']], collapse='+'), sep=''))#, env=as.environment(model.data))
        result[['adapt']] = adapt = adaptive_step(formula=f, data=model.data, family=family, weights=weights, verbose=verbose, ...)
        result[['lasso']] = lasso_step(y=y, x=as.matrix(model.data[,-response.col]), family=family, weights=weights, adaptive.object=adapt, s=s, verbose=verbose, ...)
        result[['lambda']] = c(result[['lambda']], result[['lasso']][['lambda']])
        
        change = abs(lambda.former - tail(result[['lambda']], 1))
        lambda.former = tail(result[['lambda']], 1)
        iter = iter+1
        if (verbose) {cat(paste("Change in lambda: ", change, "\n", sep=""))}
    }
    
    result[['iter']] = iter-1
    
    result[['fitted.values']] = predict(result, newx=as.matrix(model.data[,-response.col]), s=tail(result[['lambda']], 1), type="response")
    result[['actual']] = result[['adapt']][['data']][[response.name]]
    result[['residuals']] = result[['actual']] - result[['fitted.values']]
    
    return(result)
}
