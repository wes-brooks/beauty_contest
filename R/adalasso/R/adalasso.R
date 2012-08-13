adalasso <-
function(formula, data, family, weights, s=NULL, verbose=FALSE, adapt=FALSE, overshrink=FALSE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "adalasso"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    result[['data']] = data

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
    
    f = as.formula(paste(paste(response.name, "~", sep=''), paste(predictor.names, collapse='+'), sep=''))#, env=as.environment(data))
    if (adapt) {
        result[['adapt']] = adalasso_initial_step(formula=f, data=data, family=family, weights=weights, verbose=verbose)
    } else {
        result[['adapt']] = NULL
    }
    
    #Get the adaptive lasso estimate
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,-response.col])
    result[['lasso']] = adalasso_step(formula=f, data=data, family=family, weights=weights, s=s, verbose=verbose, adaptive.object=result[['adapt']], adapt=adapt, overshrink=overshrink)
    result[['lambda']] = result[['lasso']][['lambda']]
    
    result[['fitted.values']] = predict(result, newx=data)
    result[['actual']] = as.vector(data[,response.name])
    result[['residuals']] = result[['actual']] - result[['fitted.values']]
    
    return(result)
}
