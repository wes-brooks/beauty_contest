require(stringr)
require(ggplot2)
require(brooks)

root = "~/scratch/output"
#source("R/settings.r")
#root = "C:\\Users\\wrbrooks\\scratch\\output"

sites = c('hika', 'maslowski', 'kreher', 'thompson', 'point', 'neshotah', 'redarrow')
methods = c('pls', 'gbm', 'gbmcv', 'galogistic-unweighted', 'galogistic-weighted', 'adalasso-unweighted', 'adalasso-unweighted-select', 'adalasso-weighted', 'adalasso-weighted-select', 'galm', 'adapt', 'adapt-select', 'spls', 'spls-select')

#sites = c("hika")
#methods = c("gbmcv")

ROC = function(results) {
  r = results
  
  #Begin by assuming that we call every observation an exceedance
  area = 0
  spec_last = 0
  sens_last = 1
  
  sensitivity = r$tpos / (r$tpos + r$fneg)
  specificity = r$tneg / (r$tneg + r$fpos)
  
  for (k in 1:nrow(r)) {
    area = area + (specificity[k] - spec_last) * sensitivity[k]
    spec_last = specificity[k]
  }
  
  return(area)
}


results = list()
var_results = list()

for (site in sites) {
  site_results = list()
  site_var_results = list()
  
  for (method in methods) {
cat(paste("site: ", site, ", method: ", method, "\n", sep=""))
    path = paste(root, site, method, sep="/")
    filelist = list.files(path)
    indx = grep(paste("^beautyrun\\.\\d+\\.", site, "\\.", method, "\\.out", sep=""), filelist, perl=TRUE)
    files = filelist[indx]
    
    predicted = vector()
    actual = vector()
    threshold = vector()
    fold = vector()
    vars = list()
    varstring = list()
    results.table = data.frame()
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
      
      i = grep("^# results:", raw)
      
      j = grep("^# vars:", raw)
      vars[[k]] = strsplit(raw[j+1], split=", ")[[1]]
      varstring[[k]] = paste(sort(vars[[k]]), collapse=";")
      
      results.text = vector()
      for (l in (i+1):(j-1)) {
          results.text = c(results.text, raw[l])
      }
      results.table = rbind(results.table, read.table(textConnection(results.text), header=TRUE))
    }

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
    site_results[[method]] = list(res=results.table, roc=ROC(results.table))
    
    #Compute the frequency of each variable:
    predictors = colnames(read.csv(beaches[[site]][['file']], header=TRUE))
    varfreq = vector()
    for (v in predictors) {
        appearances = sum(sapply(vars, function(x) v %in% x))
        varfreq = c(varfreq, appearances/n)
    }
    site_var_results[[method]] = list(predictor.frequency=data.frame(variable=predictors, frequency=varfreq))
    
    #Compute the frequency of each unique variable combination:
    varcombo = list()
    for (v in unique(varstring)) {
        varcombo[[length(varcombo)+1]] = list(variables=v, frequency=sum(varstring==v)/n)
    }
    
    if (length(varcombo)>1) {
        #sort these results by their frequency:
        ord = order(sapply(varcombo, function(x) x[['frequency']]), decreasing=TRUE)
        varcombo = varcombo[ord]
    }
    site_var_results[[method]][['predictor.combination.frequency']] = varcombo
  }
  results[[site]] = site_results
  var_results[[site]] = site_var_results
}

  
area = matrix(NA, length(methods), length(sites))
rownames(area) = methods
colnames(area) = sites

for (site in sites) {
  for (method in methods) {
    cat(paste(method, site, results[[site]][[method]][['roc']], '\n', sep=" "))
    area[method, site] = try(results[[site]][[method]][['roc']], TRUE)
  }
}



#Make the plots
logistic_methods = c('galogistic-unweighted', 'galogistic-weighted', 'adalasso-weighted-select', 'adalasso-unweighted-select', 'adalasso-weighted', 'adalasso-unweighted')
plots = list()
for (site in sites) {
    site_plots = list()
    for (method in methods) {
        site_plots[[method]] = with(results[[site]][[method]][['res']], qplot(actual, predicted) + ggtitle(method))
        site_plots[[method]] = site_plots[[method]] + geom_vline(xintercept=2.3711, linetype='longdash', colour='red')
        #if (!(method %in% logistic_methods)) {site_plots[[method]] = site_plots[[method]] + geom_abline()}
    }
    plots[[site]] = site_plots
    
    pdf(paste("figures/", site, ".pdf", sep=""), width=16, height=20)
    multiplot(plotlist=plots[[site]], cols=3)
    dev.off()
}


