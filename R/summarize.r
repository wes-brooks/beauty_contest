#Path to the results
path = "C:\\Users\\wrbrooks\\git\\beauty_contest\\output"
#path = "~/git/beauty_contest/output"
setwd(path)

filenames = dir()

#These lists are for global use
loo_keys = list(
	tpos = list(key='^# aggregate\\.tpos = ', type='numeric'),
	tneg = list(key='^# aggregate\\.tneg = ', type='numeric'),
	fpos = list(key='^# aggregate\\.fpos = ', type='numeric'),
	fneg = list(key='^# aggregate\\.fneg = ', type='numeric'),
	roc = list(key='^# Area under ROC curve = ', type='numeric'),
	specificity = list(key='^# thresholding specificity: ', type='numeric'),
	threshold = list(key='^# decision threshold: ', type='numeric'),
	site = list(key='^# Site = ', type='string'),
	method = list(key='^# Method = ', type='string'),
	variables = list(key='^# variables: ', type='string list', sep=', '),
	frame = list(key='^# full results: ', type='data.frame', end='end')
)
loo = list()

annual_keys = list(
	tpos = list(key='^# aggregate\\.tpos = ', type='numeric'),
	tneg = list(key='^# aggregate\\.tneg = ', type='numeric'),
	fpos = list(key='^# aggregate\\.fpos = ', type='numeric'),
	fneg = list(key='^# aggregate\\.fneg = ', type='numeric'),
	roc = list(key='^# Area under ROC curve = ', type='numeric'),
	threshold = list(key="^# threshold = ", type='numeric'),
	frame = list(key='^# rocframe: ', type='data.frame', end='predperf'),
    predperf = list(key='^# predperf: ', type='data.frame', end='end')
)
annual = list()

trim <- function (x) gsub("^\\s+|\\s+$", "", x)

summarize = function(j, annual=FALSE, loo=!annual) {
	if (annual) {
		indx = grep(paste("^beautyrun\\.", j, "\\..*(?<=annual)\\.out", sep=""), filenames, perl=TRUE)
		keys = annual_keys
	} else {
		indx = grep(paste("^beautyrun\\.", j, "\\..*(?<!annual)\\.out", sep=""), filenames, perl=TRUE)
		keys = loo_keys
	}

	#Proceed only if we found the file
	if (length(indx)==0) {return(NULL)}
	
	#open the file
	name = filenames[indx]
	f = file(name, 'r')
	contents = readLines(f)
	close(f)

	#summarize the results from the file
	summary = list()

	for (k in names(keys)) {
		kk = keys[[k]]
		i = grep(kk[['key']], contents, perl=TRUE)
		
		match = regexpr(paste(kk[['key']], "(?<value>.*)$", sep=""), contents[i], perl=TRUE)
		x = attr(match, 'capture.start')[1]
		y = attr(match, 'capture.length')[1]
		
		if (kk[['type']] == 'numeric') {
		    item = as.numeric(trim(substr(contents[i], x, x+y)))
		} else if (kk[['type']] == 'string') {
		    item = trim(substr(contents[i], x, x+y))
		} else if (kk[['type']] == 'string list') {
		    item = strsplit(trim(substr(contents[i], x, x+y)), kk[['sep']])
		} else if (kk[['type']] == 'data.frame') {
		    if (kk[['end']] == 'end') {
		        end = length(contents)
		    } else {
		        end = grep(kk[['end']], contents, perl=TRUE) - 1
		    }

		    item = sapply(contents[(i+2):end], function(x) strsplit(x, '[ \\t]+', perl=TRUE))
		    item = sapply(item, as.numeric)
		    item = t(item)
		    rownames(item) = item[,1]
		    item = item[,-1]
		    colnames(item) = strsplit(contents[i+1], '[ \\t]+', perl=TRUE)[[1]][-1]
		}
		summary[[k]] = item
	}
	summary
}

settings = matrix(NA, nrow=0, ncol=3)
colnames(settings) = c('setting', 'method', 'site')
for (j in 1:98) {
	loo[[j]] = tryCatch(summarize(j, annual=FALSE), error=function(x) {return(NULL)})
	annual[[j]] = tryCatch(summarize(j-1, annual=TRUE), error=function(x) {return(NULL)})
	
	#Add some elements that were missing from the annual report:
	if (length(loo)==j & length(annual)==j) {
    	annual[[j]][['method']] = loo[[j]][['method']]
	    annual[[j]][['site']] = loo[[j]][['site']]
	    
	    settings = rbind(settings, c(j, loo[[j]][['method']], loo[[j]][['site']]))
	}
}

#Extract the site and method names from the results
sites = unique(unlist(sapply(loo, function(x) return(x[['site']]))))
methods = unique(unlist(sapply(loo, function(x) return(x[['method']]))))

#Build a site/method grid:
annual_grid = matrix(NA, nrow=length(sites), ncol=length(methods))
loo_grid = matrix(NA, nrow=length(sites), ncol=length(methods))
rownames(annual_grid) = sites
colnames(annual_grid) = methods
rownames(loo_grid) = sites
colnames(loo_grid) = methods

#Populate the site/method grid:
for (k in 1:nrow(settings)) {
    site = settings[k, 'site']
    method = settings[k, 'method']
    setting = as.numeric(settings[k, 'setting'])
    
    annual_grid[site, method] = annual[[setting]][['roc']]
    loo_grid[site, method] = loo[[setting]][['roc']]
}
    

