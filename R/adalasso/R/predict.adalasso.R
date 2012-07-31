predict.adalasso <-
function(object, newx, ...) {
    pred.data = as.matrix(newx)    
    
    if (object[['response']] %in% names(newx)) {
        response.col = which(names(newx) == object[['response']])
        pred.data = pred.data[,-response.col]
    }
    
    for (predictor in names(object[['lasso']][['coef.scale']])) {
        k = which(names(pred.data) == predictor)
        pred.data[,k] = (pred.data[,k] - object[['lasso']][['meanx']][[predictor]]) * object[['lasso']][['coef.scale']][[predictor]]
    }
    
    return(predict(object[['lasso']][['model']], newx=pred.data, ...))
}
