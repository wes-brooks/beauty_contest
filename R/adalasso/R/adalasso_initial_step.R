adalasso_initial_step <- function(formula, data, family, weights, verbose=FALSE, ...) {
    #Create the object that will hold the output
    result <- list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    response.col = which(colnames(data)==response.name)
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    #Make the calls to glm
    adaweight = list()
    coefs = list()
    for (predictor in predictor.names) {
        f = as.formula(paste(eval(response.name), "~", eval(predictor), sep=""))
        result[['model']] = model = glm(formula=f, data=data, family=family, weights=weights, ...)
        coefs[[predictor]] = coef(model)[[predictor]]
        adaweight[[predictor]] = abs(1/coefs[[predictor]])
    }
    
    result[['coefs']] = coefs
    result[['adaweight']] = adaweight    
    
    return(result)
}
