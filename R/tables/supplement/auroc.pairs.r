# pairwise comparison of AUROC for leave-one-out CV
keys = levels(roc.meanranks$method)
auroc.pairs = matrix(NA, length(keys)-1, length(keys)-1)
auroc.table = roc.meanranks %>% 
    dcast(rep~method, fun.aggregate=mean, value.var='meanrank') 

for (i in 1:(length(keys)-1)) {
    for (j in (i+1):length(keys)) {
        auroc.pairs[i,j-1] =
            auroc.table %>% 
            apply(1, function(x) x[keys[i]] > x[keys[j]]) %>% 
            mean
    }
}
colnames(auroc.pairs) = keys[2:length(keys)]
rownames(auroc.pairs) = keys[1:(length(keys)-1)]