# pairwise comparison of AUROC for leave-one-out CV
keys = levels(roc.naive.meanranks$method)
auroc.naive.pairs = matrix(NA, length(keys)-1, length(keys)-1)
auroc.naive.table = roc.naive.meanranks %>% 
    dcast(rep~method, fun.aggregate=mean, value.var='meanrank') 

for (i in 1:(length(keys)-1)) {
    for (j in (i+1):length(keys)) {
        auroc.naive.pairs[i,j-1] =
            auroc.naive.table %>% 
            apply(1, function(x) x[keys[i]] > x[keys[j]]) %>% 
            mean
    }
}
colnames(auroc.naive.pairs) = keys[2:length(keys)]
rownames(auroc.naive.pairs) = keys[1:(length(keys)-1)]

