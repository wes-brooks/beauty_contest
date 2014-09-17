#NAIVE LOYO BARCHART:
#Compute the mean ranking by combining the ranks across sites for each bootstrap replicate
roc.naive.meanranks.annual = matrix(NA, ncol=0, nrow=length(methods))
for (i in 1:S) {
    rank.naive.matrix.annual = matrix(NA, ncol=0, nrow=length(methods))
    for (site in sites) {
        rank.naive.matrix.annual = cbind(rank.naive.matrix.annual, roc.naive.ranks.annual[[site]][,i])
    }
    roc.naive.meanranks.annual = cbind(roc.naive.meanranks.annual, apply(rank.naive.matrix.annual, 1, mean))
}

#Put the ranks in a more vertical data structure
roc.naive.meanranks.annual = melt(roc.naive.meanranks.annual)
colnames(roc.naive.meanranks.annual) = c('method', 'rep', 'meanrank')

#Rename the 'method' factor levels to be sorted like the rankings (best to worst)
levl = with(roc.naive.meanranks.annual, sapply(levels(method), function(m) meanrank[method==m] %>% mean) %>%
                sort %>%
                rev %>%
                names)
roc.naive.meanranks.annual$method = factor(roc.naive.meanranks.annual$method, levels=levl)

#Bar chart of ROC rank
a = roc.naive.meanranks.annual %>%
    dcast(rep~method, fun.aggregate=mean) %>%
    apply(2, function(x) quantile(x, c(0.05,0.5,0.95))) %>%
    t %>%
    as.data.frame
a = cbind(a, method=rownames(a))[-1,]
colnames(a)[c(1,2,3)] = c('low', 'med', 'high')
a$method = factor(a$method, levels=a$method[order(a$med, decreasing=TRUE)])
roc.naive.barchart.annual = ggplot(a) +
    aes(x=method, y=med) +
    geom_bar(stat='identity', fill=gray(0.5)) +
    geom_errorbar(aes(ymin=low, ymax=high), width=0.15) +
    ylab("mean rank") + 
    xlab("(a) AUROC rank for LOYO CV") +
    ylim(0, 14) +
    scale_x_discrete(labels=a$method %>% levels %>% pretty) +
    theme_minimal() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))







