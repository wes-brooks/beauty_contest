source("R/definitions.r")

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
           #'galm',
           #'spls',
           #'spls-select',
           #'adalasso-unweighted',
           #'adalasso-weighted',
           #'galogistic-unweighted',
           #'galogistic-weighted'
           'gbm'
           )
auto = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
man = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)

#For the online supplement:
auto.complete = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)
man.complete = sapply(sites, function(s) return( sapply(select, function(m) return(vector()), simplify=FALSE) ), simplify=FALSE)

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
            
            man.indx = grep("beach|trib", colnames(v))
            auto.indx = (1:ncol(v))[-man.indx]
            
            man[[site]][[method]] = c(man[[site]][[method]], v[,man.indx] %>% rowSums %>% mean)
            auto[[site]][[method]] = c(auto[[site]][[method]], v[,auto.indx] %>% rowSums %>% mean)
        }
        
        #This gets the auto, manual vars for all methods (used in the online supplement)
        for (method in methods) {
            #Draw a new sample for point because of its multiple but unequal measurements per day
            if (site=='point') {boot = sample(1:(varlist[['point']][['adapt']] %>% nrow), replace=TRUE)}
            v = varlist[[site]][[method]]
            v = v[as.integer(boot),]  
            
            man.indx = grep("beach|trib", colnames(v))
            auto.indx = (1:ncol(v))[-man.indx]
            
            man.complete[[site]][[method]] = c(man.complete[[site]][[method]], v[,man.indx] %>% rowSums %>% mean)
            auto.complete[[site]][[method]] = c(auto.complete[[site]][[method]], v[,auto.indx] %>% rowSums %>% mean)
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
