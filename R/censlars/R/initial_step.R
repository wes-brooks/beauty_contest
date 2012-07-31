initial_step <- function(formula, data, family, weights, verbose=FALSE, left, right, ...) {
    #Create the object that will hold the output
    result <- list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    response.col = which(names(data)==response.name)
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    #Make the calls to lm
    adaweight = list()
    coefs = list()
    for (predictor in names(data)[-which(names(data)==response.name)]) {
        f = as.formula(paste(eval(response.name), "~", eval(predictor), sep=""))
        model = lm(formula=f, data=data)
        coefs[[predictor]] = coef(model)[[predictor]]
        adaweight[[predictor]] = abs(1/coefs[[predictor]])
    }
    
    result[['coefs']] = coefs
    result[['adaweight']] = adaweight
    
    return(result)
}
