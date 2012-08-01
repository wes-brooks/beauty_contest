adalars <-
function(formula, data, adapt=TRUE, overshrink=TRUE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "adalars"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    result[['data']] = data

    #Pull out the relevant data
    result[['response']] = response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    result[['predictors']] = predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(names(data)==response.name)
        
    f = as.formula(paste(paste(response.name, "~", sep=''), paste(predictor.names, collapse='+'), sep=''), env=as.environment(data))
    if (adapt) {
        result[['censreg']] = initial_step(formula=f, data=data)
    } else {
        result[['censreg']] = NULL
    }

    result[['lars']] = lars_step(formula=formula, data=data, adaptive.object=NULL, overshrink=TRUE, adapt=FALSE)
    result[['lambda']] = result[['lars']][['model']][['lambda']][result[['lars']][['lambda.index']]]
    
    result[['fitted']] = predict.adalars(result, data)
    result[['actual']] = data[[response.name]]
    result[['residuals']] = result[['actual']] - result[['fitted']]

    return(result)
}

