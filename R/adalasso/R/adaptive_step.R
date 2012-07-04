adaptive_step <-
function(formula, data, family, weights, verbose=FALSE, ...) {
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
    
    #Make the call to glm
    result[['model']] = model = glm(formula=formula, data=data, family=family, weights=weights, ...)
    coefs = as.list(coef(model))
    coefs[['(Intercept)']] = NULL
    
    adaweight = vector()
    for (name in names(data)[-which(names(data)==response.name)]) {
        if (name %in% predictor.names) {
            adaweight = c(adaweight, 1/coefs[[name]])
        } else {
            adaweight = c(adaweight, 1)
        }
    }
    
    result[['coefs']] = coefs
    result[['adaweight']] = adaweight    
    
    return(result)
}
