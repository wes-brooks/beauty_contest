#Get the number of variables selected by the adaptive lasso at each site:
nvar = data.frame()
for (s in sites) {    
    nvar.site = cbind(
        auto[[s]] %>% 
            as.data.frame %>%
            apply(2, mean),
        man[[s]] %>%
            as.data.frame %>%
            apply(2, mean))
    colnames(nvar.site) = c('auto', 'man')
    rownames(nvar.site) = NULL
    
    nvar= rbind(nvar, nvar.site %>% as.data.frame %>% cbind(site=s) %>% cbind(method=select) %>% melt)
}
colnames(nvar)[3] = "type"

#plot the number of variables at each site:
nvar.plot = nvar %>%
    melt %>%
    dcast(site + method + type ~ variable) %>%
    ggplot +
    aes(x=method, fill=type, y=value) +
    scale_fill_grey(name="Collection", start=0.7, end=0.3, labels=c('automatic', 'manual')) +
    geom_bar(stat='identity', position='dodge') +
    ylab("nvar") +
    xlab(NULL) +
    scale_x_discrete(labels=select %>% pretty) +
    theme_bw() +
    theme(legend.justification=c(1,1),
          legend.position=c(1,0.2),
          legend.text=element_text(size=rel(1.05)),
          strip.text=element_text(size=rel(1.3)),
          title=element_text(size=rel(1.3)),
          axis.text.x=element_text(angle=65, hjust=1, vjust=0.95),
          axis.text.x=element_text(angle=65, hjust=1, vjust=0.95)
    ) +
    facet_wrap(~site)