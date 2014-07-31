#Compute the mean ranking by combining the ranks across sites for each bootstrap replicate
roc.meanranks.annual = matrix(NA, ncol=0, nrow=length(methods))
for (i in 1:S) {
    rank.matrix.annual = matrix(NA, ncol=0, nrow=length(methods))
    for (site in sites) {
        rank.matrix.annual = cbind(rank.matrix.annual, roc.ranks.annual[[site]][,i])
    }
    roc.meanranks.annual = cbind(roc.meanranks.annual, apply(rank.matrix.annual, 1, mean))
}

#Put the ranks in a more vertical data structure
roc.meanranks.annual = melt(roc.meanranks.annual)
colnames(roc.meanranks.annual) = c('method', 'rep', 'meanrank')

#Rename the 'method' factor levels to be sorted like the rankings (best to worst)
levl = with(roc.meanranks.annual, sapply(levels(method), function(m) meanrank[method==m] %>% mean) %>%
                sort %>%
                rev %>%
                names)
roc.meanranks.annual$method = factor(roc.meanranks.annual$method, levels=levl)

#Bar chart of ROC rank
a = roc.meanranks.annual %>%
    dcast(rep~method, fun.aggregate=mean) %>%
    apply(2, function(x) quantile(x, c(0.05,0.5,0.95))) %>%
    t %>%
    as.data.frame
a = cbind(a, method=rownames(a))[-1,]
colnames(a)[c(1,2,3)] = c('low', 'med', 'high')
a$method = factor(a$method, levels=a$method[order(a$med, decreasing=TRUE)])
roc.barchart.annual = ggplot(a) +
    aes(x=method, y=med) +
    geom_bar(stat='identity', fill=gray(0.5)) +
    geom_errorbar(aes(ymin=low, ymax=high), width=0.15) +
    ylab("mean rank") + 
    ylim(0, 14) +
    scale_x_discrete(labels=a$method %>% levels %>% pretty) +
    theme_bw() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))
