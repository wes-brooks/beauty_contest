require(ggvis)

color = list(pls='red', gbm='blue', gbmcv='purple', adapt='orange', adapt-select='green',
             adalasso-unweighted='pink', adalasso-weighted='yellow', adalasso-unweighted-select='black',
             galogistic-unweighted='cornflowerblue', galogistic-weighted='coral4', galm='darkgoldenrod2',
             spls='darkgreen', spls-select='darkred', adalasso-weighted-select='darslateblue')

sites = names(results)
methods = names(results[['hika']])

xx = c(0,1)
yy = c(0,1)

for (site in sites) {
    exc = max(rowSums(results[[site]][['pls']][['res']][,c('tpos', 'fneg')]))
    nonexc = max(rowSums(results[[site]][['pls']][['res']][,c('tneg', 'fpos')]))
    
    for (m in methods) {
        r = results[[site]][[m]][['res']]
        pp = ggplot(r) + geom_path(aes(x=fpos/nonexc, y=tpos/exc))
        p = ggvis() + layer_path(data=r, props(x= ~fpos/nonexc, y= ~tpos/exc, stroke:=color[[m]]))
        p + layer_path(data=r, props(x= ~fpos/nonexc, y= ~tpos/exc))
        plot(c(1, r$fpos/nonexc, 0), c(1, r$tpos/exc, 0), type='l', xlim=xx, ylim=yy, bty='n', xaxt='n', yaxt='n', ann=FALSE)
        par(new=TRUE)
    }
    axis(side=0, lab='1-specificity')
    axis(side=1, lab='sensitivity')
    segments(x0=0, y0=0, x1=1, y1=1, lty='dashed')
    title(n)
}
