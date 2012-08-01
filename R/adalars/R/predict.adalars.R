predict.adalars <- 
function(obj, newx, ...) {
    pred.data = as.matrix(newx)    
    
    if (obj[['response']] %in% names(newx)) {
        response.col = which(names(newx) == obj[['response']])
        pred.data = pred.data[,-response.col]
    }
    
    for (predictor in names(obj[['lars']][['coef.scale']])) {
        k = which(names(pred.data) == predictor)
        pred.data[,k] = (pred.data[,k] - obj[['lars']][['meanx']][[predictor]]) * obj[['lars']][['coef.scale']][[predictor]]
    }

    return(predict(obj[['lars']][['model']], newx=pred.data, s=obj[['lambda']], mode='lambda', type='fit')[['fit']])
}