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


nvar.plot = list()
for (s in sites) {
    #plot the number of variables at each site:
    nvar.plot[[s]] = filter(nvar, site==s) %>%
        #melt %>%
        #dcast(site + method + type ~ variable) %>%
        ggplot +
        aes(x=type, fill=type, y=value) +
        scale_fill_grey(name="Collection", start=0.5, end=0.1, labels=c('auto', 'man')) +
        geom_bar(stat='identity', position='dodge') +
        facet_grid(.~method, labeller=function(x, j) return(lasso.and.total[j])) +
        ggtitle(pretty.sites[[s]]) +
        ylab("Number of covariates") +
        xlab(NULL) +
        #scale_x_discrete(labels=select %>% pretty) +
        theme_bw() +
        theme(#legend.justification=c(1,1),
              legend.position="none", #c(1,1),
              #legend.text=element_text(size=rel(1.05)),
              strip.text=element_text(size=rel(1.25)),
              title=element_text(size=rel(1.25)),
              axis.text.x=element_text(size=rel(2))#,
              #axis.text.x=element_text(angle=65, hjust=1, vjust=0.95)
        )
    
    yrange = max(filter(nvar, site==s)$value)
    nvar.plot[[s]] = nvar.plot[[s]] +
        geom_text(
            aes(x=c(1,2,1,2),
                y=value + yrange/50,
                label=round(value, 1)),
            hjust=0.5,
            vjust=0,
            size=rel(5)
        )
}