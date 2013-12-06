predict.censlars <- 
function(object, newx) {
    pred.data = as.matrix(newx)    
    
    if (object[['response']] %in% names(newx)) {
        response.col = which(names(newx) == object[['response']])
        pred.data = pred.data[,-response.col]
    }
    
    for (predictor in names(object[['lars']][['coef.scale']])) {
        k = which(names(pred.data) == predictor)
        pred.data[,k] = (pred.data[,k] - object[['lars']][['meanx']][[predictor]]) * object[['lars']][['coef.scale']][[predictor]]
    }

    return(predict(object[['lars']][['model']], newx=pred.data, s=tail(object[['lambda']],1), mode='lambda', type='fit')[['fit']])
}