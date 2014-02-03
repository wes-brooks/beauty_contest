predict.galogistic <-
function(obj, newx, ...) {
    predictors = obj[['vars']]
    data = newx[,predictors]

    out = predict(obj=obj[['model']], newdata=data, ...)
    return(out)
}
