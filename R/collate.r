require(stringr)

root = "~/beauty"

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
for (site in sites) {
  site_results = list()
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
    
    for (f in files) {
      raw = scan(paste(path, f, sep="/"), 'character', sep='\n')
      
      i = grep("^# predicted:", raw)
      predicted = c(predicted, as.numeric(raw[i+1]))
      
      i = grep("^# actual:", raw)
      actual = c(actual, as.numeric(raw[i+1]))
      
      i = grep("^# fold:", raw)
      fold = c(fold, as.numeric(raw[i+1]))
      
      i = grep("^# threshold:", raw)
      threshold = c(threshold, as.numeric(raw[i+1]))
      
      i = grep("^# vars:", raw)
      vars = c(vars, strsplit(raw[i+1], split=", "))
    }
    
    res = data.frame(predicted=predicted, actual=actual, fold=fold, threshold=threshold)
    res = res[order(res[['threshold']]),]
    
    tpos = rep(NA, nrow(res))
    tneg = rep(NA, nrow(res))
    fpos = rep(NA, nrow(res))
    fneg = rep(NA, nrow(res))
    
    for (t in unique(res[['threshold']])) {
      indx = which(res[['threshold']]==t)
      posindx = which(res[['threshold']]>=t)
      negindx = which(res[['threshold']]<t)
      
      tpos[indx] = sum(res$actual[posindx] > 2.3711)
      tneg[indx] = sum(res$actual[negindx] <= 2.3711)
      fpos[indx] = sum(res$actual[posindx] <= 2.3711)
      fneg[indx] = sum(res$actual[negindx] > 2.3711)
    }
    res = cbind(res, tpos, tneg, fpos, fneg)
    
    site_results[[method]] = list(res=res, vars=vars, roc=ROC(res))
  }
  results[[site]] = site_results
  
  
  sites = c('hika', 'maslowski', 'kreher', 'thompson', 'point', 'neshotah', 'redarrow')
  methods = c('pls', 'gbm', 'gbmcv', 'galogistic-unweighted', 'galogistic-weighted', 'adalasso-unweighted', 'adalasso-unweighted-select', 'adalasso-weighted', 'adalasso-weighted-select', 'galm'
              , 'spls', 'spls-select')
  
  
area = matrix(NA, length(methods), length(sites))
rownames(area) = methods
colnames(area) = sites

for (site in sites) {
  for (method in methods) {
    cat(paste(method, site, results[[site]][[method]][['roc']], '\n', sep=" "))
    area[method, site] = results[[site]][[method]][['roc']]
  }
}