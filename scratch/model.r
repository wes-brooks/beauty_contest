source("scratch/import-modules.r")
source("R/settings.r")
source('R/utils.r')

#set some values we'll use later
type = 'cv'
cluster = NA
beach = 'maritime2'
method = 'adapt'
cv_folds = 'loo'
first = TRUE
seed = 1

#Read the beach's data.
settings = beaches[[beach]]
datafile = settings[["file"]]
data = read.csv(datafile)

#Partition the data into cross-validation folds.
folds = Partition(data, folds=cv_folds)
nfolds = length(unique(folds))

if ('remove' %in% names(settings)) {
    data = data[,!(chomp(names(data)) %in% chomp(settings[['remove']]))]
}

#Apply the specified transforms to the raw data.
for (t in chomp(settings[['transforms']])) {
    data[,t] = settings[['transforms']][[t]](data[,t])
}

#Run the modeling routine
if (first) {
    #sink(paste(output, paste(prefix, beach, method, "out", sep="."), sep=''))            
    if (!is.null(seed)) {cat(paste("# Seed = ", seed, "\n", sep=''))}
    cat(paste("# Site = ", beach, "\n", sep=''))
    cat(paste("# Method = ", method, "\n", sep=''))
    #sink()
    first = FALSE
}

#Run this modeling method against the beach data.
valpar = c(params[[method]],
           list(
               data=data,
               target=settings[['target']],
               method=method,
               folds=folds,
               regulatory_threshold=settings[['threshold']]
           )
)
result = do.call(Validate, valpar)

#Prepare the results to be used in a production model
m = result[[2]]
candidates = m[['fitted']][m[['actual']] < 2.3711]
result[[1]] = cbind(result[[1]][1:3], as.vector(quantile(candidates, result[[1]][['threshold']])), result[[1]][4:8])
names(result[[1]])[3] = "tuning"
names(result[[1]])[4] = "threshold"

#Adjust the coefficients and intercept (reverse the adaptive weights)
indx = which(names(data) %in% m[['vars']])
coefs = m[['coef']] * m[['model']][['lars']][['scale']][indx-1]
intercept = m[['model']][['lars']][['Intercept']] - sum(coefs * m[['model']][['lars']][['meanx']][m[['vars']]])
