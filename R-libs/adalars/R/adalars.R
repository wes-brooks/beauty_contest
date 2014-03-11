adalars <- function(formula, data, adapt=TRUE, selection.method='AICc', selectonly=FALSE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "adalars"
    result[['formula']] = as.formula(formula, env=data)
    result[['selectonly']] = selectonly
    
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
        result[['adapt']] = adaptive_weights_lars(formula=f, data=data)
    } else {
        result[['adapt']] = NULL
    }

    result[['lars']] = adalars_step(formula=formula, data=data, adaptive.object=result[['adapt']], selection.method=selection.method, adapt=adapt)
    result[['lambda']] = result[['lars']][['model']][['lambda']][result[['lars']][['lambda.index']]]
    
    if (selectonly) {
        variables = paste(result[['lars']][['vars']], collapse="+")
        f = as.formula(paste(result[['response']], "~", variables, sep=""))
        m = lm(formula=f, data=data)
        result[['lm']] = m
        result[['coef']] = coef(m)
        result[['fitted']] = m$fitted
        result[['residuals']] = m$residuals
        result[['actual']] = m$fitted + m$residuals
    } else {    
        result[['coef']] = result[['lars']][['coef']]
        result[['actual']] = data[,response.col]
        result[['fitted']] = predict.adalars(result, data)
        result[['residuals']] = result[['actual']] - result[['fitted']]
    }

    return(result)
}

