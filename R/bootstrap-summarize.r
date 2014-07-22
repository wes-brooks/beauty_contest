require(ggplot2)
require(reshape2)
require(dplyr)

#Load the raw results of the beauty contest:
load("beauty_contest.RData")

#S is the number of bootstrap samples
S = 11

#These are data structures where we'll put the results of the bootstrap analysis
roc = sapply(sites, function(s) return( sapply(methods, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
roc.ranks = list()

#Calculate the PRESS only for continuous response:
conts = c('adapt', 'adapt-select', 'gbm', 'gbmcv', 'pls', 'galm', 'spls', 'spls-select')
press = sapply(sites, function(s) return( sapply(conts, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
press.ranks = list()

#These lists will hold the number of manual and automatic variables for each bootstrap resample:
select = c('adapt', 'galm', 'spls', 'spls-select',
           'adalasso-unweighted',
           'adalasso-weighted',
           'galogistic-unweighted', 'galogistic-weighted')
auto = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
man = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)

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
            
            #Get the decision-accuracy of the modeling method.
            #First, sort the results based on the decision threshold
            r = r[order(r$threshold),]
            
            #Summarize the correctness of decisions over this bootstrap sample
            tpos = rep(NA, n)
            tneg = rep(NA, n)
            fpos = rep(NA, n)
            fneg = rep(NA, n)
            
            #For each possible decision compute the projected confusion matrix
            for (t in unique(r$threshold)) {
                indx = which(r$threshold == t)
                posindx = which(r$threshold >= t)
                negindx = which(r$threshold < t)
                
                tpos[indx] = sum(r$actual[posindx] > 2.3711)
                tneg[indx] = sum(r$actual[negindx] <= 2.3711)
                fpos[indx] = sum(r$actual[posindx] <= 2.3711)
                fneg[indx] = sum(r$actual[negindx] > 2.3711)
            }
            r = cbind(r, tpos, tneg, fpos, fneg)
            
            #Now add the area under this ROC curve to the vector of bootstrap outputs:
            roc[[site]][[method]] = c(roc[[site]][[method]], ROC(r))
        }
        
        for (method in conts) {
            #Compute the PRESS and add it to the list:
            press[[site]][[method]] = c(press[[site]][[method]],
                with(results[[site]][[method]][['res']], (predicted-actual)[as.numeric(boot)])**2 %>% sum)
        }
        
#         for (method in select) {
#             v = varlist[[site]][[method]]
#             v = v[as.integer(boot),]  
#             
#             man.indx = grep("beach", colnames(v))
#             auto.indx = (1:ncol(v))[-man.indx]
#             
#             man[[site]][[method]] = c(man[[site]][[method]], v[,man.indx] %>% rowSums %>% mean)
#             auto[[site]][[method]] = c(auto[[site]][[method]], v[,auto.indx] %>% rowSums %>% mean)
#         }
    }
    
    #put the results in a data frame and rank the methods on each bootstrap sample:
    roc[[site]] = data.frame(roc[[site]])
    roc.ranks[[site]] = apply(roc[[site]], 1, rank)
    
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

#Make a boxplot of the distribution of ranks, computed by the bootstrap:
LOO.auroc.boxplot = ggplot(roc.meanranks) +
    aes(x=method, y=meanrank) +
    geom_boxplot() +
    xlab("modeling technique") + 
    ylab("mean rank") + 
    ylim(0, 14) +
    scale_x_discrete(labels=roc.meanranks$method %>% levels %>% addline_format) +
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
levl = with(press.meanranks, sapply(levels(method), function(m) meanrank[method==m] %>% mean) 
            %>% sort 
            %>% rev 
            %>% names)
press.meanranks$method = factor(press.meanranks$method, levels=levl)

#Make a boxplot of the distribution of ranks, computed by the bootstrap:
LOO.press.boxplot = ggplot(press.meanranks) +
    aes(x=method, y=meanrank) +
    geom_boxplot() + 
    xlab("modeling technique") + 
    ylab("mean rank") + 
    ylim(0, 8) +
    scale_x_discrete(labels=press.meanranks$method %>% levels %>% addline_format) +
    theme_bw()


# nvar.plot = list()
# for (s in sites) {
#     nvar.mean = rbind(auto[[s]] %>%
#                         as.data.frame %>%
#                         melt(variable.name='method') %>%
#                         cbind('type'=rep('auto',S)),
#                     man[[s]] %>%
#                         as.data.frame %>%
#                         melt(variable.name='method') %>%
#                         cbind('type'=rep('man',S))) %>%
#                     dcast(method~type, fun.aggregate=mean) %>%
#                     melt(variable.name='type') 
#     
# #     nvar.range = cbind(
# #                     auto[[s]] %>%
# #                         as.data.frame %>%
# #                         apply(2, range),
# #                     man[[s]] %>%
# #                         as.data.frame %>%
# #                         apply(2, range))
# #     rownames(nvar.range) = c('min', 'max')
# #     
# #     nvar.data = cbind(nvar.mean, t(nvar.range))
#     
#     nvar.plot[[s]] = nvar.data %>%
#         ggplot +
#             aes(x=method, fill=type, y=value) +
#             geom_bar(stat='identity', position='dodge') +
#             #geom_errorbar(aes(ymin=min, ymax=max), width=.1) +
#             ylab("nvar") +
#             ggtitle(s) +
#             scale_x_discrete(labels=select %>% addline_format) +
#             theme_bw() +
#             theme(legend.justification=c(1,1),
#                   legend.position=c(1,1),
#                   legend.text=element_text(size=rel(1.05)),
#                   strip.text=element_text(size=rel(1.3)),
#                   title=element_text(size=rel(1.3)),
#                   axis.text.x=element_text(angle=65, hjust=1, vjust=0.95),
#                   axis.text.x=element_text(angle=65, hjust=1, vjust=0.95)
#             )
#             
# }