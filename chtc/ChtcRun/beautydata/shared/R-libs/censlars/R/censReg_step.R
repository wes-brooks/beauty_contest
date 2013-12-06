censReg_step <-
function(formula, data, left=-Inf, right=Inf, prev.object) {
    #Create the object that will hold the output
    result = list()
    result[['formula']] = as.formula(formula)
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    #Drop any rows with NA values
    model.data = data[,c(response.name, predictor.names)]
    
    #Make the call to censReg
    result[['model']] = censReg(formula=formula, data=model.data, left=left, right=right)
    coefs = coef(result[['model']])
    
    adaweight = list()
    for (predictor in names(data)[-which(names(data)==response.name)]) {
        if (predictor %in% predictor.names) {
            adaweight[[predictor]] = 1 / coefs[[predictor]]
        } else {
            adaweight[[predictor]] = prev.object[['adaweight']][[predictor]]
        }
    }
    result[['adaweight']] = adaweight
    
    #Include some additional data in the wrapped object:
    result[['logSigma']] = result[['model']]$estimate[['logSigma']]
    result[['coef']] = result[['model']]$estimate[1:(length(predictor.names)+1)]
    result[['x']] = as.matrix(cbind(rep(1,dim(model.data)[1]), model.data[,-1]))
    result[['actual']] = model.data[,response.name]
    result[['fitted']] = result[['x']] %*% as.matrix(result[['coef']])
    result[['latent']] = sapply(1:length(result[['actual']]), function(x) {ifelse(result[['actual']][x]<=left, min(result[['fitted']][x], left), ifelse(result[['actual']][x]>=right, max(result[['fitted']][x], right), result[['actual']][x]))})
    
    return(result)
}

