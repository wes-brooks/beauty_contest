adalars <-
function(formula, data, adapt=TRUE, overshrink=TRUE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "adalars"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    result[['data']] = data

    #Pull out the relevant data
    result[['response']] = rownames(attr(terms(formula, data=data), 'factors'))[1]
    result[['predictors']] = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==result[['response']])
        
    f = as.formula(paste(paste(result[['response']], "~", sep=''), paste(result[['predictors']], collapse='+'), sep=''), env=as.environment(data))
    if (adapt) {
        result[['adapt']] = adalars_initial_step(formula=f, data=data)
    } else {
        result[['adapt']] = NULL
    }

    result[['lars']] = adalars_step(formula=formula, data=data, adaptive.object=result[['adapt']], overshrink=overshrink, adapt=adapt)
    result[['lambda']] = result[['lars']][['model']][['lambda']][result[['lars']][['lambda.index']]]
    
    result[['fitted']] = predict.adalars(result, data)
    result[['actual']] = data[,result[['response']]]
    result[['residuals']] = result[['actual']] - result[['fitted']]

    return(result)
}

