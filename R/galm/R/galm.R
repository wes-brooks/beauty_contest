galm <-
function(formula, data, population=200, generations=100, mutateRate=0.02, zeroOneRatio=10, ...) {
    #Create the object that will hold the output
    result = list()
    class(result) = "adalasso"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
        
    m = ncol(data)
    n = nrow(data)

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(names(data)==response.name)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
        
    f = as.formula(paste(paste(response.name, "~", sep=''), paste(predictor.names, collapse='+'), sep=''))#, env=as.environment(data))
    
    #Get the initial lasso estimate
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,-response.col])
    
    #Maximum number of predictor variables:
    m = ncol(data) - 1
    result[['ga']] = rbga.bin(size=m, zeroToOneRatio=zeroOneRatio, evalFunc=evalBIC, monitorFunc=monitor, mutationChance=mutateRate, popSize=population, iters=generations, verbose=TRUE)
    
    indx = which.min(result[['ga']]$evaluations)
    indiv = as.logical(drop(result[["ga"]]$population[indx,]))
    
    result[['vars']] = predictor.names[indiv]
    result[['formula']] = as.formula(paste(response.name, "~", paste(result[['vars']], collapse="+"), sep=""))
    result[["model"]] = lm(formula=result[['formula']], data=data)
    class(result) = "galm"
    
    result
}
