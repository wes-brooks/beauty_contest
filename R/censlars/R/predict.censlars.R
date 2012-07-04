predict.censlars <- 
function(object, newx) {
    #pred.data = as.matrix(newx[,object[['lars']][['vars']]])
    pred.data = as.matrix(newx)
    print(paste("Predictiing with s=", object[['lars']][['lambda.index']], sep=''))
    return(predict.lars(object[['lars']][['model']], newx=pred.data, type='fit', s=object[['lars']][['lambda.index']], mode='step')$fit)
}