censlars <-
function(formula, data, left=-Inf, right=Inf, max.iter=10, tol=1e-25, adapt=TRUE, overshrink=TRUE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "censlars"
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
    response.col = which(colnames(data)==response.name)
        
    f = as.formula(paste(paste(response.name, "~", sep=''), paste(predictor.names, collapse='+'), sep=''), env=as.environment(data))
    if (adapt) {
        result[['censreg']] = censlars_initial_step(formula=f, data=data, left=left, right=right)
    } else {
        result[['censreg']] = NULL
    }
        

    result[['lars']] = censlars_step(formula=formula, data=data, adaptive.object=NULL, overshrink=TRUE, adapt=FALSE)
    
    #prepare for iteration
    iter = 1
    change = tol+1
    lambda.former = result[['lars']][['model']][['lambda']][result[['lars']][['lambda.index']]]
    result[['lambda']] = c(lambda.former)    
    
    #Repeat until convergence
    while (iter<=max.iter && change>tol) {
        #Use censReg to impute the logEC
        f = as.formula(paste(paste(response.name, "~", sep=''), paste(result[['lars']][['vars']], collapse='+'), sep=''), env=as.environment(data))
        result[['censreg']] = censReg_step(formula=f, data=data, left=left, right=right, prev.object=result[['censreg']])
        
        #Now fit the LARS model
        result[['lars']] = censlars_step(formula=f, data=data, adaptive.object=result[['censreg']], overshrink=overshrink, adapt=adapt)
        result[['lambda']] = c(result[['lambda']], result[['lars']][['model']][['lambda']][result[['lars']][['lambda.index']]])
        
        change = abs(lambda.former - tail(result[['lambda']], 1))
        lambda.former = tail(result[['lambda']], 1)
        iter = iter+1
    }
    
    result[['iter']] = iter-1
    return(result)
}

