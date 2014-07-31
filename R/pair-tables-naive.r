#This is a formatting function to put newlines in the column labels
tabulate_headers <- function(x,...){
    res = gsub('[.-]', ' \\\\\\\\ '
               , x, perl=TRUE)
    res = paste("\\begin{tabular}{l}", res, "\\end{tabular}", sep="")
    res
}




# pairwise comparison of AUROC for leave-one-year-out CV
keys = levels(roc.naive.meanranks.annual$method)
auroc.naive.pairs.annual = matrix(NA, length(keys)-1, length(keys)-1)
auroc.naive.table.annual = roc.naive.meanranks.annual %>% 
    dcast(rep~method, fun.aggregate=mean, value.var='meanrank') 

for (i in 1:(length(keys)-1)) {
    for (j in (i+1):length(keys)) {
        auroc.naive.pairs.annual[i,j-1] =
            auroc.naive.table.annual %>% 
            apply(1, function(x) x[keys[i]] > x[keys[j]]) %>% 
            mean
    }
}
colnames(auroc.naive.pairs.annual) = keys[2:length(keys)]
rownames(auroc.naive.pairs.annual) = keys[1:(length(keys)-1)]






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
