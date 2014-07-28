#This is a formatting function to put newlines in the column labels
tabulate_headers <- function(x,...){
    res = gsub('[.-]', ' \\\\\\\\ '
               , x, perl=TRUE)
    res = paste("\\begin{tabular}{l}", res, "\\end{tabular}", sep="")
    res
}


# pairwise comparison of PRESS for leave-one-year-out CV
keys = levels(press.meanranks.annual$method)
press.pairs.annual = matrix(NA, length(keys)-1, length(keys)-1)
press.table.annual = press.meanranks.annual %>% 
    dcast(rep~method, fun.aggregate=mean, value.var='meanrank') 

for (i in 1:(length(keys)-1)) {
    for (j in (i+1):length(keys)) {
        press.pairs.annual[i,j-1] =
            press.table.annual %>% 
            apply(1, function(x) x[keys[i]] > x[keys[j]]) %>% 
            mean
    }
}
colnames(press.pairs.annual) = keys[2:length(keys)]
rownames(press.pairs.annual) = keys[1:(length(keys)-1)]



# pairwise comparison of AUROC for leave-one-year-out CV
keys = levels(roc.meanranks.annual$method)
auroc.pairs.annual = matrix(NA, length(keys)-1, length(keys)-1)
auroc.table.annual = roc.meanranks.annual %>% 
    dcast(rep~method, fun.aggregate=mean, value.var='meanrank') 

for (i in 1:(length(keys)-1)) {
    for (j in (i+1):length(keys)) {
        auroc.pairs.annual[i,j-1] =
            auroc.table.annual %>% 
            apply(1, function(x) x[keys[i]] > x[keys[j]]) %>% 
            mean
    }
}
colnames(auroc.pairs.annual) = keys[2:length(keys)]
rownames(auroc.pairs.annual) = keys[1:(length(keys)-1)]






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

