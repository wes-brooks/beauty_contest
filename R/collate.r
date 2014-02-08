require(stringr)

sites = c('hika', 'maslowski', 'kreher', 'thompson', 'point', 'neshotah', 'redarrow')
methods = c('pls', 'gbm', 'gbmcv', 'galogistic-unweighted', 'galogistic-weighted', 'adalasso-unweighted', 'adalasso-unweighted-select', 'adalasso-weighted', 'adalasso-weighted-select', 'galm', 'adapt', 'adapt-select', 'spls', 'spls-select')

sites = c("thompson")
methods = c("gbmcv")

results = list()
for (site in sites) {
  site_results = list()
  for (method in methods) {
    indx = grep(paste("^beautyrun\\.\\d+\\.", "thompson", "\\.", "gbmcv", "\\.out", sep=""), dir(), perl=TRUE)
    files = dir()[indx]
    
    predicted = vector()
    actual = vector()
    threshold = vector()
    fold = vector()
    
    for (f in files) {
      raw = scan(file, 'character', sep='\n')
      
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
    
    site_results[[method]] = list(predicted, actual, fold, threshold, vars)
  }
  results[[site]] = site_results
}