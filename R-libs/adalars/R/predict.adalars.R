predict.adalars <-  function(obj, newx) {
    pred.data = newx
    predictors = obj[['predictors']]
    colnames(pred.data) = colnames(newx)
    pred.data = pred.data[,predictors]
    
    if (obj[['selectonly']]) {
        predictions = predict(obj[['lm']], newx)
    } else {
        if (obj[['response']] %in% colnames(pred.data)) {
            response.col = which(colnames(pred.data) == obj[['response']])
            pred.data = pred.data[,-response.col]
        }
        
        for (predictor in predictors) {
            pred.data[[predictor]] = (pred.data[[predictor]] - obj[['lars']][['meanx']][[predictor]]) * obj[['lars']][['coef.scale']][[predictor]]
        }
		
        predictions = predict(obj[['lars']][['model']], newx=pred.data, s=obj[['lambda']], mode='lambda', type='fit')[['fit']]
    }
    
    return(predictions)
}
