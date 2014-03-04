predict.adalasso <- function(obj, newx) {
    pred.data = newx
    predictors = obj[['predictors']]
    colnames(pred.data) = colnames(newx)
    pred.data = pred.data[,predictors]
    
    if (obj[['selectonly']]) {
        predictions = predict(obj[['glm']], newx, type='response')
    } else {
        pred.data = sweep(pred.data, 2, obj[['lasso']][['meanx']], '-')
        pred.data = sweep(pred.data, 2, obj[['lasso']][['scale']], '*')
        
        predictions = predict(obj[['lasso']][['model']], newx=as.matrix(pred.data), type='response', s=obj[['lambda']])
    }
    
    return(predictions)
}
