beaches = list()
beaches[['hika']] = list('file'='data/HK2013.2.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
beaches[['kreher']] = list('file'='data/KR2013.2.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
beaches[['maslowski']] = list('file'='data/MS2013.2.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
beaches[['neshotah']] = list('file'='data/NS2013.2.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
beaches[['point']] = list('file'='data/PointAll.2.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
beaches[['redarrow']] = list('file'='data/RA2013.2.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue ', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
beaches[['thompson']] = list('file'='data/TH2013.2.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())


params = list()
params[["PLS"]] = list('env'=PLS)

params[["gbm"]] = list('env'=GBM, 'depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=10000, 'shrinkage'=0.0005, 'gbm.folds'=0)
params[["gbmcv"]] = list('env'=GBM, 'depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=10000, 'shrinkage'=0.0005, 'gbm.folds'=5)

params[['galogistic-unweighted']] = list('env'=GALogistic, 'weights'='none', 'generations'=100, 'mutate'=0.05)
params[['galogistic-weighted']] = list('env'=GALogistic, 'weights'='continuous', 'generations'=100, 'mutate'=0.05)

params[['adalasso-unweighted']] = list('env'=LAL, 'weights'='none', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE)
params[['adalasso-unweighted-select']] = list('env'=LAL, 'weights'='none', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE, 'selectvars'=TRUE)
params[['adalasso-weighted']] = list('env'=LAL, 'weights'='continuous', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE)
params[['adalasso-weighted-select']] = list('env'=LAL, 'weights'='continuous', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE, 'selectvars'=TRUE)

params[["galm"]] = list('env'=GALM, 'generations'=100, 'mutate'=0.05)

params[["adapt"]] = list('env'=AL, 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE, 'selectvars'=FALSE)
params[["adapt-select"]] = list('env'=AL, 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE, 'selectvars'=TRUE)

params[["spls"]] = list('env'=SPLS, 'selectvars'=FALSE)
params[["spls-select"]] = list('env'=SPLS, 'selectvars'=TRUE)
