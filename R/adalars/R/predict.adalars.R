predict.adalars <- 
function(obj, newx, ...) {
    pred.data = as.matrix(newx)    
    predictors = obj[['lars']][['predictors']]
    colnames(pred.data) = colnames(newx)
    pred.data = pred.data[,predictors]
    
    if (obj[['response']] %in% colnames(pred.data)) {
        response.col = which(colnames(pred.data) == obj[['response']])
        pred.data = pred.data[,-response.col]
    }
    
    for (predictor in predictors) {
        k = which(colnames(pred.data)==predictor)
        pred.data[,predictor] = (pred.data[,predictor] - obj[['lars']][['meanx']][[predictor]]) * obj[['lars']][['coef.scale']][[predictor]]
    }
    
    predictions = predict(obj[['lars']][['model']], newx=pred.data, s=obj[['lambda']], mode='lambda', type='fit')[['fit']]
    return(predictions)
}