for (b in sites) {

act = results[[b]][['gbm']][['res']][['actual']]

#Establish the limist of the plot
xlim = range(c(act, results[[b]][['gbm']][['res']][['predicted']]), na.rm=TRUE)
ylim = range(c(act, results[[b]][['adapt']][['res']][['predicted']]), na.rm=TRUE)

#plot(act, act, xlim=xlim, ylim=ylim, bty='n', xaxt='n', yaxt='n', ann=FALSE, col='red')

#for (i in 1:length(act)) {    
#    par(new=TRUE)
#    lines(x=c(act[i], results[[b]][['gbm']][['res']][['predicted']][i]),
#          y=c(act[i], results[[b]][['adapt']][['res']][['predicted']][i]),
#          col='red')
#}

#Make the plot of gbm vs adapt predictions
plot(results[[b]][['gbm']][['res']][['predicted']],
     results[[b]][['adapt']][['res']][['predicted']],
     xlim=xlim,
     ylim=ylim,
     bty='n',
     xlab="GBM",
     ylab="Adaptive lasso",
     main=b)
}