predict.adalars <-  function(obj, newx) {
    pred.data = newx
    predictors = obj[['predictors']]
    colnames(pred.data) = colnames(newx)
    pred.data = pred.data[,predictors]
    
    if (obj[['selectonly']]) {
        predictions = predict(obj[['lm']], newx)
    } else {
        pred.data = sweep(pred.data, 2, obj[['lars']][['meanx']], '-')
        pred.data = sweep(pred.data, 2, obj[['lars']][['scale']], '*')
        predictions = predict(obj[['lars']][['model']], newx=pred.data, s=obj[['lars']][['lambda.index']], mode='step', type='fit')[['fit']]
    }
    
    return(predictions)
}
