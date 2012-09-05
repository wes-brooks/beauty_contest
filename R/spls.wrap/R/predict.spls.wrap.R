predict.spls.wrap <-
function(obj, newx) {   
    n = nrow(newx)
    p = length(obj[['coef']])
    b = as.matrix(obj[['coef']])
    x = as.matrix(newx[,obj[['predictors']]])
    
    return(obj[['Intercept']] + x %*% b)
}
