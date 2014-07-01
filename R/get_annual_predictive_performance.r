method = "spls-select"
site = "redarrow"
f = 1
crit = 2.3711

# extract just the results of interest:
ra = results_annual[[site]][[method]][['res']]

#This is the table to hold results:
perf = matrix(NA, nrow=0, ncol=5)

for (f in unique(ra$fold)) {
    indx.fold = 1:sum(ra$fold == f)
    thresh = sum(ra$actual[ra$fold!=f] <= crit) / sum(ra$fold != f)
    which.exc = which(ra$actual[ra$fold == f] > crit)
    which.post = which(ra$threshold[ra$fold == f] > thresh)
    
    tp = sum(which.post %in% which.exc)
    tn = sum(!(indx.fold %in% which.post) & !(indx.fold %in% which.exc))
    fp = sum(!(which.post %in% which.exc))
    fn = sum(!(which.exc %in% which.post))
    
    perf = rbind(perf, c(tp, tn, fp, fn, thresh))
}