predict.galm <-
function(obj, newx, ...) {
    data = newx[,obj[['vars']]]
    out = predict(obj=obj[['model']], newdata=data)
    
    out
}
