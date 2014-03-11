adaptive_weights_glmnet <- function(formula, data, family, weights, verbose) {
    #Create the object that will hold the output
    result <- list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    response.col = which(colnames(data)==response.name)
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    response = as.matrix(data[,response.col])
    x = as.matrix(data[,-response.col])

    #Set up the lists to hold the adaptive weights:
    result[['meanx']] = colMeans(x)
    x.centered = sweep(x, 2, result[['meanx']])

    result[['normx']] = apply(x.centered, 2, function(x) sqrt(sum(x**2)))
    result[['normx']] = sapply(result[['normx']], function(x) ifelse(x==0, Inf, x))
    x.standardized = sweep(x.centered, 2, result[['normx']]**(-1), '*')
    colnames(x.standardized) = predictor.names
    
    #Make the calls to glm
    coefs = list()
    for (predictor in predictor.names) {
        if (result[['normx']][[predictor]] < Inf) {
            model = glm(response~x.standardized[,predictor], family=family, weights=weights)
        
            coefs[[predictor]] = coef(model)[2]
        } else {
            coefs[[predictor]] = 0
        }
    }
    
    result[['coef']] = coefs
    result[['adaweight']] = sapply(predictor.names, function(x) {abs(coefs[[x]]) / result[['normx']][[x]]})
    
    return(result)
}
