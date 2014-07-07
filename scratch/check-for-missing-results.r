#annual:
for (site in sites) {
    n = NULL
    
    for (method in methods) {
        ra = results_annual[[site]][[method]][['res']]
        
        #Check whether all four folds are represented:
        if (length(unique(ra$fold)) != 4) {
            cat(paste(site, method, paste(sort(unique(ra$fold)), collapse=","), "\n", sep=" "))
        }
        
        if (is.null(n)) {
            n = dim(ra)[1]
        } else if (n != dim(ra)[1]) {
            cat(paste(site, method, n, "\n", sep=" "))
        }
    }
}
        

#LOO
for (site in sites) {
    n = NULL
    
    for (method in methods) {
        rr = results[[site]][[method]][['res']]
        
        #Check whether all four folds are represented:
        if (site == 'point') {
            if (length(unique(rr$fold)) != 191 | nrow(rr) != 562) {
                cat(paste(site, method, paste(sort(unique(rr$fold)), collapse=","), "\n", sep=" "))
            }
        } else {
            if (length(unique(rr$fold)) != nrow(rr)) {
                cat(paste(site, method, paste(sort(unique(rr$fold)), collapse=","), "\n", sep=" "))
            }
        }
        
        #if (is.null(n)) {
        #    n = nrow(rr)
        #} else if (n != nrow(rr)) {
        #    cat(paste(site, method, n, "\n", sep=" "))
        #}
    }
}