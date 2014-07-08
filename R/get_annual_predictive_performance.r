require(dplyr)
require(reshape)

#Set up some variables and an object to hold the results:
confusion.methods = c('gbm', 'adapt')
perf = sapply(confusion.methods, function(m) sapply(sites, function(s) return(matrix(NA, ncol=5, nrow=0)), simplify=FALSE), simplify=FALSE)
crit = 2.3711

for (method in confusion.methods) {
    for (site in sites) {
        pp = perf[[method]][[site]]
        
        # extract just the results of interest:
        ra = results_annual[[site]][[method]][['res']]
        
        #find the prediction performance based on the new thresholding method:
        for (f in ra$fold %>% unique %>% sort) {
            indx.fold = 1:sum(ra$fold == f)
            thresh = sum(ra$actual[ra$fold!=f] <= crit) / sum(ra$fold != f)
            which.exc = which(ra$actual[ra$fold == f] > crit)
            which.post = which(ra$threshold[ra$fold == f] > thresh)
            
            tp = sum(which.post %in% which.exc)
            tn = sum(!(indx.fold %in% which.post) & !(indx.fold %in% which.exc))
            fp = sum(!(which.post %in% which.exc))
            fn = sum(!(which.exc %in% which.post))
            
            pp = rbind(pp, c(tp, tn, fp, fn, thresh))
        }
        
        #add an aggregation row and put row, column names on the perf data:
        pp = rbind(pp, colSums(pp))
        colnames(pp) = c('tp', 'tn', 'fp', 'fn', 'thresh')
        rownames(pp) = c('1', '2', '3', '4', 'tot')
        
        #return this perf data to the main result object:
        perf[[method]][[site]] = pp
    }
}

#Reshape the perf data to get just the interesting parts:
perf = melt(perf)
colnames(perf) = c('fold', 'type', 'count', 'site', 'method')
perf = filter(perf, fold=='tot', type!='thresh')
perf$flag = perf$type %in% c('tp', 'fp')
perf$exceedance = perf$type %in% c('tp', 'fn')
perf$accurate = perf$flag == perf$exceedance

#plot the results:
pp = list()
for (s in sites) {
    pp[[s]] = ggplot(filter(perf, site==s)) +
        aes(x=exceedance, y=count, fill=factor(accurate, levels=c("TRUE", "FALSE"))) +
        scale_fill_grey(start=0.5, end=0.1, labels=c('accurate', 'misclassified')) +
        geom_bar(stat='identity', position='dodge') +
        facet_wrap(~method) +
        aes(order=rev(accurate)) +
        theme_bw() + 
        scale_x_discrete(labels=c('nonexceedances','exceedances')) +
        xlab(NULL) + 
        labs(fill=NULL) +
        theme(legend.justification=c(1,1), legend.position=c(1,1))
}

