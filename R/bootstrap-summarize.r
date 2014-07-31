require(ggplot2)
require(reshape2)
require(dplyr)

#Load the raw results of the beauty contest:
load("beauty_contest.RData")
load("variable_supplement.RData")
source("R/ROC.r")

#S is the number of bootstrap samples
S = 50

#These are data structures where we'll put the results of the bootstrap analysis
roc = sapply(sites, function(s) return( sapply(methods, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
roc.ranks = list()

#These are data structures where we'll put the results of the bootstrap analysis
roc.naive = sapply(sites, function(s) return( sapply(methods, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
roc.naive.ranks = list()

#Calculate the PRESS only for continuous response:
conts = c('adapt', 'adapt-select', 'gbm', 'gbmcv', 'pls', 'galm', 'spls', 'spls-select')
press = sapply(sites, function(s) return( sapply(conts, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
press.ranks = list()

#These lists will hold the number of manual and automatic variables for each bootstrap resample:
select = c('adapt',
           'gbm'
           #'galm',
           #'spls',
           #'spls-select',
           #'adalasso-unweighted',
           #'adalasso-weighted',
           #'galogistic-unweighted',
           #'galogistic-weighted'
           )
auto = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
man = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)

for (s in sites) {
    for (m in methods) {
        varlist[[s]][[m]] = varlist[[s]][[m]] %>% as.matrix
    }
}
varlist[['point']] = lapply(varlist[['point']], function(x) x[1:191,])

#This section computes bootstrap estimates of the ranks of the modeling methods
for (site in sites) {
    n = nrow(results[[site]][[methods[1]]][['res']])
    
    #Loop through the bootstrap replicates
    for (j in 1:S) {
        #The indices that make up this bootstrap draw:
        boot = as.character(sample(1:n, replace=TRUE))
        
        #Use the same indices to resample results from each method:
        for (method in methods) {
            #Draw the botstrap sample for this method, using the indices in 'boot'
            r = results[[site]][[method]][['res']][,1:4]
            r = r[boot,]
            colnames(r) = c('predicted', 'actual', 'threshold', 'fold')
            
            #Now add the area under this ROC curve to the vector of bootstrap outputs:
            roc[[site]][[method]] = c(roc[[site]][[method]], ROC(r))
            roc.naive[[site]][[method]] = c(roc.naive[[site]][[method]], ROC.naive(r))
        }
        
        for (method in conts) {
            #Compute the PRESS and add it to the list:
            press[[site]][[method]] = c(press[[site]][[method]],
                with(results[[site]][[method]][['res']], (predicted-actual)[as.numeric(boot)])**2 %>% sum)
        }
        
        for (method in select) {
            #Draw a new sample for point because of its multiple but unequal measurements per day
            if (site=='point') {boot = sample(1:(varlist[['point']][['adapt']] %>% nrow), replace=TRUE)}
            v = varlist[[site]][[method]]
            v = v[as.integer(boot),]  
            
            man.indx = grep("beach", colnames(v))
            auto.indx = (1:ncol(v))[-man.indx]
            
            man[[site]][[method]] = c(man[[site]][[method]], v[,man.indx] %>% rowSums %>% mean)
            auto[[site]][[method]] = c(auto[[site]][[method]], v[,auto.indx] %>% rowSums %>% mean)
        }
    }
    
    #put the results in a data frame and rank the methods on each bootstrap sample:
    roc[[site]] = data.frame(roc[[site]])
    roc.ranks[[site]] = apply(roc[[site]], 1, rank)

    #put the results in a data frame and rank the methods on each bootstrap sample:
    roc.naive[[site]] = data.frame(roc.naive[[site]])
    roc.naive.ranks[[site]] = apply(roc.naive[[site]], 1, rank)
    
    #put the results in a data frame and rank the methods on each bootstrap sample:
    press[[site]] = data.frame(press[[site]])
    press.ranks[[site]] = apply(-press[[site]], 1, rank)
}

    
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


#This is a formatting function to put newlines in the plot labels
addline_format <- function(x,...){
    gsub('[.-]', '\n', x, perl=TRUE)
}

roc.range = cbind(dcast(roc.meanranks, method~'min', min),
                  dcast(roc.meanranks, method~'max', max)) %>% melt


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
    scale_x_discrete(labels=a$method %>% levels %>% addline_format) +
    theme_bw() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))






#Do the same for PRESS:
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

#Bar chart of ROC rank
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
    ylim(0, 8) +
    scale_x_discrete(labels=a$method %>% levels %>% addline_format) +
    theme_bw() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))

#Get the number of variables selected by the adaptive lasso at each site:
nvar = data.frame()
for (s in sites) {    
    nvar.site = cbind(
                    auto[[s]] %>%
                        as.data.frame %>%
                        apply(2, function(x) quantile(x, c(0.05, 0.5, 0.95))),
                    man[[s]] %>%
                        as.data.frame %>%
                        apply(2, function(x) quantile(x, c(0.05, 0.5, 0.95))))
    rownames(nvar.site) = c('low', 'med', 'high')
    colnames(nvar.site) = NULL
    
    nvar= rbind(nvar, nvar.site %>% t %>% as.data.frame %>% cbind(site=s) %>% cbind(method=select) %>% cbind(type=c(rep('auto',2), rep('man',2))))
}


#plot the number of variables at each site:
nvar.plot = nvar %>%
    melt %>%
    dcast(site + method + type ~ variable) %>%
    ggplot +
    aes(x=method, fill=type, y=med) +
    scale_fill_grey(name="Collection", start=0.7, end=0.3, labels=c('automatic', 'manual')) +
    geom_bar(stat='identity', position='dodge') +
    geom_errorbar(aes(ymin=low, ymax=high), width=0.15, position=position_dodge(width=0.9)) +
    ylab("nvar") +
    xlab(NULL) +
    scale_x_discrete(labels=select %>% addline_format) +
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