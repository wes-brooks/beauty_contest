#Path to the results
path = "C:\\Users\\wrbrooks\\git\\beauty_contest\\output"
setwd(path)

filenames = dir()

#These lists are for global use
loo_keys = list(
	tpos='^# aggregate\\.tpos = ',
	tneg='^# aggregate\\.tneg = ',
	fpos='^# aggregate\\.fpos = ',
	fneg='^# aggregate\\.fneg = ',
	roc='^# Area under ROC curve = ',
	specificity='^# thresholding specificity: ',
	threshold='^# decision threshold: '
)
loo = list()

annual_keys = list(
	tpos='^# aggregate\\.tpos = ',
	tneg='^# aggregate\\.tneg = ',
	fpos='^# aggregate\\.fpos = ',
	fneg='^# aggregate\\.fneg = ',
	roc='^# Area under ROC curve = ',
	threshold="^# threshold = "
)
annual = list()


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
		i = grep(kk, contents, perl=TRUE)
		
		match = regexpr(paste(kk, "(?<value>[\\.\\d]+)", sep=""), contents[i], perl=TRUE)
		x = attr(match, 'capture.start')[1]
		y = attr(match, 'capture.length')[1]
		
		item = as.numeric(substr(contents[i], x, x+y))
		summary[[k]] = item
	}
	
	summary
}


for (j in 1:5) {
	loo[[j]] = summarize(j, annual=FALSE)
	annual[[j]] = summarize(j, annual=TRUE)
}