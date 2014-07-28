require(ggplot2)

root = "~/Dropbox/beauty/output"
#root = "C:\\Users\\wrbrooks\\Dropbox\\beauty\\output"

sites = c('hika', 'maslowski', 'kreher', 'thompson', 'point', 'neshotah', 'redarrow')
methods = c('pls', 'gbm', 'gbmcv', 'galogistic-unweighted', 'galogistic-weighted', 'adalasso-unweighted', 'adalasso-unweighted-select', 'adalasso-weighted', 'adalasso-weighted-select', 'galm', 'adapt', 'adapt-select', 'spls', 'spls-select')

source("R/ROC.r")

results_annual = list()
var_results_annual = list()

for (site in sites) {
    site_results = list()
    site_var_results = list()
    
    for (method in methods) {
cat(paste("site: ", site, ", method: ", method, "\n", sep=""))
        path = paste(root, site, method, sep="/")
        filelist = list.files(path)
        indx = grep(paste("^beautyrun\\.\\d+\\.", site, "\\.", method, "\\.annual\\.out", sep=""), filelist, perl=TRUE)
        files = filelist[indx]
        
        predicted = vector()
        actual = vector()
        threshold = vector()
        fold = vector()
        vars = list()
        varstring = list()
        results.table = data.frame()
        predperf.table = data.frame()
        k=0
        
        for (f in files) {
cat(paste("file: ", f, "\n", sep=""))
            k = k+1
            ff = file(paste(path, f, sep="/"), open='r')
            raw = scan(ff, 'character', sep='\n')
            close(ff)
            
            #Garbage-collect the connection because the system sets a maximum that we'd otherwise exceed:
            rm(ff)
            gc()
            
            i = grep("^# rocframe:", raw)
            j = grep("^# predperf:", raw)
            
            results.text = vector()
            for (l in (i+1):(j-1)) {
                results.text = c(results.text, raw[l])
            }
            results.table = rbind(results.table, read.table(textConnection(results.text), header=TRUE))
            
            predperf.text = vector()
            for (l in (j+1):length(raw)) {
                predperf.text = c(predperf.text, raw[l])
            }
            predperf.table = rbind(predperf.table, read.table(textConnection(predperf.text), header=TRUE))
        }
        #Make sure the rownames are sequential and aligned with the observation order
        rownames(results.table) = NULL
        rownames(results.table) = 1:nrow(results.table)
        
        #Get the decision-accuracy of the modeling method.
        #First, sort the results based on the decision threshold
        results.table = results.table[order(results.table[['threshold']]),]
        
        n = nrow(results.table)
        tpos = rep(NA, n)
        tneg = rep(NA, n)
        fpos = rep(NA, n)
        fneg = rep(NA, n)
        
        #For each possible decision compute the projected confusion matrix
        for (t in unique(results.table[['threshold']])) {
            indx = which(results.table[['threshold']]==t)
            posindx = which(results.table[['threshold']]>=t)
            negindx = which(results.table[['threshold']]<t)
            
            tpos[indx] = sum(results.table$actual[posindx] > 2.3711)
            tneg[indx] = sum(results.table$actual[negindx] <= 2.3711)
            fpos[indx] = sum(results.table$actual[posindx] <= 2.3711)
            fneg[indx] = sum(results.table$actual[negindx] > 2.3711)
        }
        results.table = cbind(results.table, tpos, tneg, fpos, fneg)
        
        #Now produce the area under the ROC curve:
        site_results[[method]] = list(res=results.table, roc=ROC(results.table), predperf=predperf.table)
    }
    results_annual[[site]] = site_results
    var_results_annual[[site]] = site_var_results
}


area_annual = matrix(NA, length(methods), length(sites))
rownames(area_annual) = methods
colnames(area_annual) = sites

for (site in sites) {
    for (method in methods) {
        cat(paste(method, site, results_annual[[site]][[method]][['roc']], '\n', sep=" "))
        area_annual[method, site] = try(results_annual[[site]][[method]][['roc']], TRUE)
    }
}

#Create a flat table of the area under the ROC curve:
flatarea_annual = list('site'=vector(), 'method'=vector(), 'area'=vector())
for (r in 1:ncol(area_annual)) {
    flatarea_annual[['site']] = c(flatarea_annual[['site']], rep(colnames(area_annual)[r], nrow(area_annual)))
    flatarea_annual[['method']] = c(flatarea_annual[['method']], rownames(area_annual))
    flatarea_annual[['area']] = c(flatarea_annual[['area']], as.numeric(area_annual[,r]))
}
flatarea_annual = as.data.frame(flatarea_annual)


#plot the area under the ROC curve:
areaplot = ggplot(flatarea)
ggplot(flatarea) + aes(x=site, y=area, fill=method) + geom_bar(stat='identity', position='dodge')
ggplot(flatarea) + aes(x=method, y=area, fill=method) + geom_bar(stat='identity') + facet_wrap(~site)

temp = as.matrix(rowMeans(apply(area_annual, 2, rank)))
temp = data.frame(method=rownames(temp), meanrank=temp)
temp = temp[rev(order(temp$meanrank)), ]
temp$method = factor(temp$method, levels=as.character(temp$method))
rownames(temp) = NULL

rocranks_annual = temp

addline_format <- function(x,...){
    gsub('-', '\n', x, fixed=TRUE)
}

ggplot(rocranks_annual) +
    aes(x=method, y=meanrank) +
    geom_bar(stat='identity') +
    theme(axis.text.x=element_text(angle=45, hjust=0.8, vjust=0.8)) + 
    xlab("modeling technique") + 
    ylab("mean rank") + 
    scale_x_discrete(labels=addline_format(rocranks_annual$method))