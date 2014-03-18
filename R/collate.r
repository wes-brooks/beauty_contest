require(stringr)
require(ggplot2)
require(brooks)

root = "~/misc/b2/output"
#root = "C:\\Users\\wrbrooks\\scratch\\output"

sites = c('hika', 'maslowski', 'kreher', 'thompson', 'point', 'neshotah', 'redarrow')
methods = c('pls', 'gbm', 'gbmcv', 'galogistic-unweighted', 'galogistic-weighted', 'adalasso-unweighted', 'adalasso-unweighted-select', 'adalasso-weighted', 'adalasso-weighted-select', 'galm', 'adapt', 'adapt-select', 'spls', 'spls-select')

#sites = c("thompson")
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
    path = paste(root, site, method, sep="/")
    filelist = list.files(path)
    indx = grep(paste("^beautyrun\\.\\d+\\.", site, "\\.", method, "\\.out", sep=""), filelist, perl=TRUE)
    files = filelist[indx]
    
    predicted = vector()
    actual = vector()
    threshold = vector()
    fold = vector()
    vars = list()
    results.table = data.frame()
    k=0
    
    for (f in files) {
      k = k+1
      raw = scan(paste(path, f, sep="/"), 'character', sep='\n')
      
      i = grep("^# results:", raw)
      
      j = grep("^# vars:", raw)
      vars[[k]] = strsplit(raw[j+1], split=", ")
      
      results.text = vector()
      for (l in (i+1):(j-1)) {
          results.text = c(results.text, raw[l])
      }
      results.table = rbind(results.table, read.table(textConnection(results.text), header=TRUE))
    }
        
    results.table = results.table[order(results.table[['threshold']]),]

    n = nrow(results.table)
    tpos = rep(NA, n)
    tneg = rep(NA, n)
    fpos = rep(NA, n)
    fneg = rep(NA, n)
    
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
    
    site_results[[method]] = list(res=results.table, roc=ROC(results.table))
    site_var_results[[method]] = vars
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


