predict.censlars <- 
function(object, newx, ...) {
    if (object[['response']] %in% names(newx)) {
        response.col = which(names(newx) == object[['response']])
        pred.data = pred.data[,-response.col]
    }
    
    pred.data = scale(pred.data, center=object[['lasso']][['meanx']], scale=1/object[['lasso']][['coef.scale']])
    return(predict(object[['lars']][['model']], newx=pred.data, ...))
}