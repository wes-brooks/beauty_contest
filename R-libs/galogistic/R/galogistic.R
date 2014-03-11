galogistic <-function(formula, data, population=200, generations=100, mutateRate=0.02, zeroOneRatio=10, verbose=TRUE, family, weights=NULL) {
    #Create the object that will hold the output
    result = list()
    
    #Drop any rows with NA values
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
        
    m = ncol(data)
    n = nrow(data)

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
    
    #Maximum number of predictor variables:
    m = ncol(data) - 1
    result[['ga']] = rbga.bin.logistic(size=m, zeroToOneRatio=zeroOneRatio, evalFunc=evalAICc_logistic, monitorFunc=galogistic_monitor, mutationChance=mutateRate, popSize=population, iters=generations, verbose=verbose, data=data, output=result[['response']], family=family, weights=weights)
    
    indx = which.min(result[['ga']]$evaluations)
    indiv = as.logical(drop(result[["ga"]]$population[indx,]))
    
    result[['vars']] = predictor.names[indiv]
    result[['formula']] = as.formula(paste(response.name, "~", paste(result[['vars']], collapse="+"), sep=""))
    result[["model"]] = glm(formula=result[['formula']], data=data, family=family, weights=weights)
    
    result[['fitted']] = fitted(result[['model']])
    result[['residuals']] = residuals(result[['model']])
    result[['actual']] = data[,response.col]
    
    class(result) = "galogistic"
    
    result
}
