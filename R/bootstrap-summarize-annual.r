require(ggplot2)
require(dplyr)

#Load the raw results of the beauty contest:
load("beauty_contest.RData")

#S is the number of bootstrap samples
S = 101

#These are data structures where we'll put the results of the bootstrap analysis
roc.annual = sapply(sites, function(s) return( sapply(methods, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
ranks.annual = list()

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
    }
    
    #put the results in a data frame and rank the methods on each bootstrap sample:
    roc.annual[[site]] = data.frame(roc.annual[[site]])
    ranks.annual[[site]] = apply(roc.annual[[site]], 1, rank)
}

#Compute the mean ranking by combining the ranks across sites for each bootstrap replicate
meanranks.annual = matrix(NA, ncol=0, nrow=length(methods))
for (i in 1:S) {
    rank.matrix.annual = matrix(NA, ncol=0, nrow=length(methods))
    for (site in sites) {
        rank.matrix.annual = cbind(rank.matrix.annual, ranks.annual[[site]][,i])
    }
    meanranks.annual = cbind(meanranks.annual, apply(rank.matrix.annual, 1, mean))
}

#Put the ranks in a more vertical data structure
meanranks.annual = melt(meanranks.annual)
colnames(meanranks.annual) = c('method', 'rep', 'meanrank')

#Rename the 'method' factor levels to be sorted like the rankings (best to worst)
levl = with(meanranks.annual, sapply(levels(method), function(m) meanrank[method==m] %>% mean) 
            %>% sort 
            %>% rev 
            %>% names)
meanranks.annual$method = factor(meanranks.annual$method, levels=levl)

#This is a formatting function to put newlines in the plot labels
addline_format <- function(x,...){
    gsub('.', '\n', x, fixed=TRUE)
}

#Make a boxplot of the distribution of ranks, computed by the bootstrap:
annual.boxplot = ggplot(meanranks.annual) +
    aes(x=method, y=meanrank) +
    geom_boxplot() +
    theme(axis.text.x=element_text(angle=45, hjust=0.8, vjust=0.8)) + 
    xlab("modeling technique") + 
    ylab("mean rank") + 
    scale_x_discrete(labels=meanranks.annual$method %>% levels %>% addline_format)