predict.censlars <- 
function(object, newx, ...) {
    if (object[['response']] %in% names(newx)) {
        response.col = which(names(newx) == object[['response']])
        pred.data = newx[,-response.col]
    } else {
        pred.data = newx
    }
    
    pred.data = scale(pred.data, center=object[['lars']][['meanx']], scale=1/object[['lars']][['coef.scale']])
    return(predict(object[['lars']][['model']], newx=pred.data, s=tail(object[['lambda']],1), mode='lambda', type='fit')[['fit']])
}