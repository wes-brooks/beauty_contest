ROC = function(r) {
    #Get the decision-accuracy of the modeling method.
    #First, sort the results based on the decision threshold
    n = nrow(r)
    a = r$actual[order(r$threshold)]
    
    tpos = sapply(1:n, function(i) sum(a[i:n] > 2.3711))
    tneg = sapply(1:n, function(i) sum(a[0:(i-1)] <= 2.3711))
    fpos = sapply(1:n, function(i) sum(a[i:n] <= 2.3711))
    fneg = sapply(1:n, function(i) sum(a[0:(i-1)] > 2.3711))
    r = as.data.frame(cbind(tpos, tneg, fpos, fneg))
   
    #Begin by assuming that we call every observation an exceedance
    area = 0
    spec_last = 0
    sens_last = 1
    
    sensitivity = r$tpos / (r$tpos + r$fneg)
    specificity = r$tneg / (r$tneg + r$fpos)
    
    for (k in 1:nrow(r)) {
        area = area + (specificity[k] - spec_last) * sensitivity[k]
        spec_last = specificity[k]
    }
    
    return(area)
}


ROC.naive = function(r) {
    #Recompute the results table based on raw predictions
    n = nrow(r)
    r = r[order(r$predicted),1:2]
    
    tpos = sapply(1:n, function(i) sum(r$actual[i:n]>2.3711))
    tneg = sapply(1:n, function(i) sum(r$actual[0:(i-1)]<=2.3711))
    fpos = sapply(1:n, function(i) sum(r$actual[i:n]<=2.3711))
    fneg = sapply(1:n, function(i) sum(r$actual[0:(i-1)]>2.3711))
    r = as.data.frame(cbind(tpos, tneg, fpos, fneg))
    
    #Begin by assuming that we call every observation an exceedance
    area = 0
    spec_last = 0
    sens_last = 1
    
    sensitivity = r$tpos / (r$tpos + r$fneg)
    specificity = r$tneg / (r$tneg + r$fpos)
    
    for (k in 1:nrow(r)) {
        area = area + (specificity[k] - spec_last) * sensitivity[k]
        spec_last = specificity[k]
    }
    
    return(area)
}