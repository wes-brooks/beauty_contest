adalasso <-
function(formula, data, family, weights, s=NULL, verbose=FALSE, adapt=TRUE, selection.method='AICc', selectonly=FALSE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "adalasso"
    result[['formula']] = as.formula(formula, env=data)
    result[['selectonly']] = selectonly
    
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
    
    f = as.formula(paste(paste(response.name, "~", sep=''), paste(predictor.names, collapse='+'), sep=''))
    if (adapt) {
        result[['adapt']] = adaptive_weights_glmnet(formula=f, data=data, family=family, weights=weights, verbose=verbose)
    } else {
        result[['adapt']] = NULL
    }
    
    #Get the adaptive lasso estimate
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,-response.col])
    result[['lasso']] = adalasso_step(formula=f, data=data, family=family, weights=weights, s=s, verbose=verbose, adaptive.object=result[['adapt']], adapt=adapt, selection.method=selection.method)
    result[['lambda']] = result[['lasso']][['lambda']]
    
    if (selectonly) {
        variables = paste(result[['lasso']][['vars']], collapse="+")
        f = as.formula(paste(result[['response']], "~", variables, sep=""))
        m = glm(formula=f, data=data, family=family, weights=weights)
        result[['glm']] = m
        result[['fitted.values']] = m$fitted
        result[['actual']] = as.vector(data[,response.name])
        result[['residuals']] = result[['actual']] - result[['fitted.values']]
    } else {    
        result[['fitted.values']] = predict(result, newx=data)
        result[['actual']] = as.vector(data[,response.name])
        result[['residuals']] = result[['actual']] - result[['fitted.values']]
    }
        
    return(result)
}
