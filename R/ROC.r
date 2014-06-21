ROC = function(results) {
    r = results
    
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