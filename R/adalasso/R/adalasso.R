adalasso <-
function(formula, data, family, weights, max.iter=20, tol=1e-25, s=NULL, verbose=FALSE, adapt=TRUE, overshrink=FALSE, ...) {
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
    if (adapt) {
        result[['adapt']] = adapt = initial_step(formula=f, data=model.data, family=family, weights=weights, verbose=verbose, ...)
    } else {
        result[['adapt']] = NULL
    } 
    
    #Get the initial lasso estimate
    y = as.matrix(model.data[,response.col])
    x = as.matrix(model.data[,-response.col])
    result[['lasso']] = lasso_step(y=y, x=x, family=family, weights=weights, s=s, verbose=verbose, adaptive.object=adapt, adapt=FALSE, overshrink=FALSE, ...)
    result[['lambda']] = result[['lasso']][['lambda']]
    
    result[['fitted.values']] = predict(result, newx=as.matrix(model.data[,-response.col]), s=tail(result[['lambda']], 1), type="response")
    #result[['actual']] = result[['adapt']][['data']][[response.name]]
    result[['actual']] = as.vector(model.data[,response.name])
    result[['residuals']] = result[['actual']] - result[['fitted.values']]
    
    return(result)
}
