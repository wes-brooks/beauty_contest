require(ggplot2)
require(reshape2)
require(dplyr)

#Load the raw results of the beauty contest:
load("beauty_contest.RData")

#S is the number of bootstrap samples
S = 1001

#These are data structures where we'll put the results of the bootstrap analysis
roc.annual = sapply(sites, function(s) return( sapply(methods, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
roc.ranks.annual = list()

#Calculate the PRESS only for continuous response:
conts = c('adapt', 'adapt-select', 'gbm', 'gbmcv', 'pls', 'galm', 'spls', 'spls-select')
press.annual = sapply(sites, function(s) return( sapply(conts, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
press.ranks.annual = list()

#This section computes bootstrap estimates of the ranks of the modeling methods
for (site in sites) {
    n = nrow(results_annual[[site]][[methods[1]]][['res']])
    
    #Loop through the bootstrap replicates
    for (j in 1:S) {
        #The indices that make up this bootstrap draw:
        boot = as.character(sample(1:n, replace=TRUE))
        
        for (method in methods) {
            #Draw the botstrap sample for this method, using the indices in 'boot'
            r = results_annual[[site]][[method]][['res']][,1:4]
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
            roc.annual[[site]][[method]] = c(roc.annual[[site]][[method]], ROC(r))
        }
        
        for (method in conts) {
            #Compute the PRESS and add it to the list:
            press.annual[[site]][[method]] = c(press.annual[[site]][[method]],
                with(results_annual[[site]][[method]][['res']], (predicted-actual)[as.numeric(boot)])**2 %>% sum)
        }
    }
    
    #put the results in a data frame and rank the methods on each bootstrap sample:
    roc.annual[[site]] = data.frame(roc.annual[[site]])
    roc.ranks.annual[[site]] = apply(roc.annual[[site]], 1, rank)
    
    #put the results in a data frame and rank the methods on each bootstrap sample:
    press.annual[[site]] = data.frame(press.annual[[site]])
    press.ranks.annual[[site]] = apply(-press.annual[[site]], 1, rank)
}

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

#This is a formatting function to put newlines in the plot labels
addline_format <- function(x,...){
    gsub('.', '\n', x, fixed=TRUE)
}


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
    scale_x_discrete(labels=a$method %>% levels %>% addline_format) +
    theme_bw() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))




#Do the same for PRESS:
#Compute the mean ranking by combining the ranks across sites for each bootstrap replicate
press.meanranks.annual = matrix(NA, ncol=0, nrow=length(conts))
for (i in 1:S) {
    rank.matrix.annual = matrix(NA, ncol=0, nrow=length(conts))
    for (site in sites) {
        rank.matrix.annual = cbind(rank.matrix.annual, press.ranks.annual[[site]][,i])
    }
    press.meanranks.annual = cbind(press.meanranks.annual, apply(rank.matrix.annual, 1, mean))
}

#Put the ranks in a more vertical data structure
press.meanranks.annual = melt(press.meanranks.annual)
colnames(press.meanranks.annual) = c('method', 'rep', 'meanrank')

#Rename the 'method' factor levels to be sorted like the rankings (best to worst)
levl = with(press.meanranks.annual, sapply(levels(method), function(m) meanrank[method==m] %>% mean) 
            %>% sort 
            %>% rev 
            %>% names)
press.meanranks.annual$method = factor(press.meanranks.annual$method, levels=levl)

#Bar chart of ROC rank
a = press.meanranks.annual %>%
    dcast(rep~method, fun.aggregate=mean) %>%
    apply(2, function(x) quantile(x, c(0.05,0.5,0.95))) %>%
    t %>%
    as.data.frame
a = cbind(a, method=rownames(a))[-1,]
colnames(a)[c(1,2,3)] = c('low', 'med', 'high')
a$method = factor(a$method, levels=a$method[order(a$med, decreasing=TRUE)])
press.barchart.annual = ggplot(a) +
    aes(x=method, y=med) +
    geom_bar(stat='identity', fill=gray(0.5)) +
    geom_errorbar(aes(ymin=low, ymax=high), width=0.15)+
    ylab("mean rank") + 
    ylim(0, 8) +
    scale_x_discrete(labels=a$method %>% levels %>% addline_format) +
    theme_bw() +
    theme(axis.text.x=element_text(angle=65, hjust=1, vjust=0.95))

