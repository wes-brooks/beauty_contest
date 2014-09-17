#Compute the mean ranking by combining the ranks across sites for each bootstrap replicate
press.meanranks = matrix(NA, ncol=0, nrow=length(conts))
for (i in 1:S) {
    rank.matrix = matrix(NA, ncol=0, nrow=length(conts))
    for (site in sites) {
        rank.matrix = cbind(rank.matrix, press.ranks[[site]][,i])
    }
    press.meanranks = cbind(press.meanranks, apply(rank.matrix, 1, mean))
}

#Put the ranks in a more vertical data structure
press.meanranks = melt(press.meanranks)
colnames(press.meanranks) = c('method', 'rep', 'meanrank')

#Rename the 'method' factor levels to be sorted like the rankings (best to worst)
levl = with(press.meanranks, sapply(levels(method), function(m) meanrank[method==m] %>% mean)  %>%
                sort %>%
                rev %>%
                names)
press.meanranks$method = factor(press.meanranks$method, levels=levl)

#Bar chart of PRESS rank
a = press.meanranks %>%
    dcast(rep~method, fun.aggregate=mean) %>%
    apply(2, function(x) quantile(x, c(0.05,0.5,0.95))) %>%
    t %>%
    as.data.frame
a = cbind(a, method=rownames(a))[-1,]
colnames(a)[c(1,2,3)] = c('low', 'med', 'high')
a$method = factor(a$method, levels=a$method[order(a$med, decreasing=TRUE)])
press.barchart = ggplot(a) +
    aes(x=method, y=med) +
    geom_bar(stat='identity', fill=gray(0.5)) +
    geom_errorbar(aes(ymin=low, ymax=high), width=0.15)+
    ylab("mean rank") + 
    xlab("(d) PRESS rank for LOO CV") +
    ylim(0, 8) +
    scale_x_discrete(labels=a$method %>% levels %>% pretty) +
    theme_minimal() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))
