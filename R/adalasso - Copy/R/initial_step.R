initial_step <- function(formula, data, family, weights, verbose=FALSE, ...) {
    #Create the object that will hold the output
    result <- list()
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    #Drop any rows with NA values
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    result[['data']] = data
    
    #Make the calls to glm
    adaweight = vector()
    coefs = list()
    for (predictor in names(data)[-which(names(data)==response.name)]) {
        f = as.formula(paste(eval(response.name), "~", eval(predictor), sep=""))
        result[['model']] = model = glm(formula=f, data=data, family=family, weights=weights, ...)
        coefs[[predictor]] = coef(model)[[predictor]]
        adaweight = c(adaweight, abs(1/coefs[[predictor]]))
    }
    
    result[['coefs']] = coefs
    result[['adaweight']] = adaweight    
    
    return(result)
}
