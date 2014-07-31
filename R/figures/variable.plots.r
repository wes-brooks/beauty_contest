varplots = list()

for (site in sites) {
    site_data = var_summary[[site]][['adapt']][['predictor.frequency']]
    site_data$beachvar = rep(FALSE, nrow(site_data))
    site_data$beachvar[grep("beach", site_data$variable)] = TRUE
    
    indx = order(site_data$frequency, decreasing=TRUE)
    pdata = site_data[indx,]
    pdata = pdata[which(pdata$frequency>0),]
    pdata$variable = factor(pdata$variable, levels=as.character(pdata$variable))
    
    p = ggplot(pdata)
    varplots[[site]] = p + aes(x=variable, y=frequency, fill=factor(beachvar)) +
        scale_fill_grey(name="Collection", start=0.7, end=0.3, labels=c('automatic', 'manual')) +
        geom_bar(stat='identity') +
        xlab("Variable") +
        ylab("Frequency selected") +
        theme_bw() +
        theme(legend.justification=c(1,1),
              legend.position=c(1,1),
              legend.text=element_text(size=rel(1.05)),
              strip.text=element_text(size=rel(1.3)),
              title=element_text(size=rel(1.3))
        ) +
        theme(axis.text.x=element_text(angle=85, hjust=1, vjust=0.98))   
}
