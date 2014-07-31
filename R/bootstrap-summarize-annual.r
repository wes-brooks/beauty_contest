source("R/definitions.r")

#These are data structures where we'll put the results of the bootstrap analysis
roc.annual = sapply(sites, function(s) return( sapply(methods, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
roc.ranks.annual = list()

#These are data structures where we'll put the results of the bootstrap analysis
roc.naive.annual = sapply(sites, function(s) return( sapply(methods, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
roc.naive.ranks.annual = list()

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
            
            #Now add the area under this ROC curve to the vector of bootstrap outputs:
            roc.annual[[site]][[method]] = c(roc.annual[[site]][[method]], ROC(r))
            roc.naive.annual[[site]][[method]] = c(roc.naive.annual[[site]][[method]], ROC.naive(r))
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
    roc.naive.annual[[site]] = data.frame(roc.naive.annual[[site]])
    roc.naive.ranks.annual[[site]] = apply(roc.naive.annual[[site]], 1, rank)
    
    #put the results in a data frame and rank the methods on each bootstrap sample:
    press.annual[[site]] = data.frame(press.annual[[site]])
    press.ranks.annual[[site]] = apply(-press.annual[[site]], 1, rank)
}

