predict.adalasso <-
function(obj, newx) {
    pred.data = as.matrix(newx)    
    predictors = obj[['predictors']]
    colnames(pred.data) = colnames(newx)
    pred.data = pred.data[,predictors]
    
    if (obj[['response']] %in% colnames(pred.data)) {
        response.col = which(colnames(pred.data) == obj[['response']])
        pred.data = pred.data[,-response.col]
    }
    
    for (predictor in predictors) {
        pred.data[,predictor] = (pred.data[,predictor] - obj[['lasso']][['meanx']][[predictor]]) * obj[['lasso']][['coef.scale']][[predictor]]
    }
    
    predictions = predict(obj[['lasso']][['model']], newx=pred.data, type='response', s=obj[['lambda']])
    return(predictions)
}
