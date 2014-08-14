# pairwise comparison of PRESS for leave-one-out CV
keys = levels(press.meanranks$method)
press.pairs = matrix(NA, length(keys)-1, length(keys)-1)
press.table = press.meanranks %>% 
    dcast(rep~method, fun.aggregate=mean, value.var='meanrank') 

for (i in 1:(length(keys)-1)) {
    for (j in (i+1):length(keys)) {
        press.pairs[i,j-1] =
            press.table %>% 
            apply(1, function(x) x[keys[i]] > x[keys[j]]) %>% 
            mean
    }
}
colnames(press.pairs) = keys[2:length(keys)]
rownames(press.pairs) = keys[1:(length(keys)-1)]