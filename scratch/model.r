source("scratch/import-modules.r")
source("R/settings.r")
source('R/utils.r')

#set some values we'll use later
type = 'cv'
cluster = NA
beach = 'point'
method = 'adapt'
cv_folds = 5
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

