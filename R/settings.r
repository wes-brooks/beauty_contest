beaches = list()
##beaches[['edgewater']] = list('file'='../data/edgewater.xls', 'target'='LogEC', 'transforms'=list(), 'remove'=c('id', 'year', 'month'), 'threshold'=2.3711)
##beaches[['redarrow']] = list('file'='../data/RedArrow2010-11_for_workshop.xls', 'target'='EColiValue', 'transforms'=list('EColiValue'=log10), 'remove'=c('pdate'), 'threshold'=2.3711)
##beaches[['redarrow']] = list('file'='../data/RA-VB1.xlsx', 'target'='logEC', 'remove'=c('beachEColiValue', 'CDTTime', 'beachTurbidityBeach', 'tribManitowocRiverTribTurbidity'), 'threshold'=2.3711, 'transforms'=c())
beaches[['hika']] = list('file'='../data/HK2013.MaxRowsTurb.csv', 'target'='log_beach_EColi', 'remove'=c('beach_EColiValue', 'surveyDatetime'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['fisher']] = list('file'='../data/Fisher.csv', 'target'='observation', 'remove'=c('beachEColiValue', 'datetime'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['kreher']] = list('file'='../data/Kreher.csv', 'target'='logecoli', 'remove'=c('beachEColiValue', 'dates'], 'threshold'=2.3711, 'transforms'=list())
#beaches[['maslowski']] = list('file'='../data/Maslowski.csv', 'target'='logecoli', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['neshotah']] = list('file'='../data/Neshotah.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['pointconcessions']] = list('file'='../data/PointConcessions.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['pointlakeshore']] = list('file'='../data/PointLakeshore.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['pointlighthouse']] = list('file'='../data/PointLighthouse.csv', 'target'='logec', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['redarrow']] = list('file'='../data/RedArrow.csv', 'target'='logecoli', 'remove'=c('beachEColiValue', 'CDTTime'), 'threshold'=2.3711, 'transforms'=list())
#beaches[['thompson']] = list('file'='../data/Thompson.csv', 'target'='observation', 'remove'=c('beachEColiValue', 'dates'), 'threshold'=2.3711, 'transforms'=list())
##beaches[['huntington']] = list('file'='../data/HuntingtonBeach.csv', 'target'='logecoli', 'remove'=c(), 'threshold'=2.3711, 'transforms'=list())

params = list()
##params[["lasso"]] = list('left'=0, 'right'=3.383743576, 'adapt'=True, 'overshrink'=True, 'precondition'=False)
params[["PLS"]] = list()
params[["gbm"]] = list('depth'=5, 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=0)
#params[["gbmcv"]] = list('depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=20000, 'shrinkage'=0.0001, 'gbm.folds'=5)
##params[['logistic']] = list('weights'='discrete', 'stepdirection'='both')

#params[['galogistic-unweighted']] = list('weights'='none', 'generations'=100, 'mutate'=0.05)
#params[['galogistic-weighted']] = list('weights'='continuous', 'generations'=100, 'mutate'=0.05)
#params[['adalasso-unweighted']] = list('weights'='none', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE)
#params[['adalasso-unweighted-select']] = list('weights'='none', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE, 'selectvars'=TRUE)
#params[['adalasso-weighted']] = list('weights'='continuous', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE)
#params[['adalasso-weighted-select']] = list('weights'='continuous', 'adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE, 'selectvars'=TRUE)
params[["galm"]] = list('generations'=5, 'mutate'=0.05)
#params[["adapt"]] = list('adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=FALSE, 'selectvars'=FALSE)
#params[["adapt-select"]] = list('adapt'=TRUE, 'overshrink'=TRUE, 'precondition'=False, 'selectvars'=TRUE)
#params[["spls"]] = list('selectvars'=False)
#params[["spls-select"]] = list('selectvars'=TRUE)


params[["gbm"]] = list('depth'=5, 'weights'='none', 'minobsinnode'=5, 'iterations'=1000, 'shrinkage'=0.01, 'gbm.folds'=0)
methods = list(
	#'gbm' = GBM
	#'pls' = PLS
	'galm' = GALM
	#adapt = AL
	#'spls-select' = SPLS
	#'adalasso-weighted' = LAL
	#'galogistic-weighted' = GALogistic
)