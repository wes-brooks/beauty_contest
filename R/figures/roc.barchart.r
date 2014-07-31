#Compute the mean ranking by combining the ranks across sites for each bootstrap replicate
roc.meanranks = matrix(NA, ncol=0, nrow=length(methods))
for (i in 1:S) {
    rank.matrix = matrix(NA, ncol=0, nrow=length(methods))
    for (site in sites) {
        rank.matrix = cbind(rank.matrix, roc.ranks[[site]][,i])
    }
    roc.meanranks = cbind(roc.meanranks, apply(rank.matrix, 1, mean))
}

#Put the ranks in a more vertical data structure
roc.meanranks = melt(roc.meanranks)
colnames(roc.meanranks) = c('method', 'rep', 'meanrank')

#Rename the 'method' factor levels to be sorted like the rankings (best to worst)
levl = with(roc.meanranks, sapply(levels(method), function(m) meanrank[method==m] %>% mean) 
            %>% sort 
            %>% rev 
            %>% names)
roc.meanranks$method = factor(roc.meanranks$method, levels=levl)

#Bar chart of ROC rank
a = roc.meanranks %>% dcast(rep~method, fun.aggregate=mean) %>% apply(2, function(x) quantile(x, c(0.05,0.5,0.95))) %>% t %>% as.data.frame
a = cbind(a, method=rownames(a))[-1,]
colnames(a)[c(1,2,3)] = c('low', 'med', 'high')
a$method = factor(a$method, levels=a$method[order(a$med, decreasing=TRUE)])
roc.barchart = ggplot(a) +
    aes(x=method, y=med) +
    geom_bar(stat='identity', fill=gray(0.5)) +
    geom_errorbar(aes(ymin=low, ymax=high), width=0.15)+
    ylab("mean rank") + 
    ylim(0, 14) +
    scale_x_discrete(labels=a$method %>% levels %>% pretty) +
    theme_bw() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))
