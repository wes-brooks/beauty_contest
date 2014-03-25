require(ggvis)

color = list(pls='red', gbm='blue', gbmcv='purple', adapt='orange', 'adapt-select'='green',
             'adalasso-unweighted'='pink', 'adalasso-weighted'='yellow', 'adalasso-unweighted-select'='black',
             'galogistic-unweighted'='cornflowerblue', 'galogistic-weighted'='coral4', galm='darkgoldenrod2',
             spls='darkgreen', 'spls-select'='darkred', 'adalasso-weighted-select'='darslateblue')

sites = names(results)
methods = names(results[['hika']])

xx = c(0,1)
yy = c(0,1)

for (site in sites) {
    exc = max(rowSums(results[[site]][['pls']][['res']][,c('tpos', 'fneg')]))
    nonexc = max(rowSums(results[[site]][['pls']][['res']][,c('tneg', 'fpos')]))
    p = ggvis()
    
    for (m in methods) {
        r = results[[site]][[m]][['res']]
        p = p + layer_path(data=r, props(x= ~fpos/nonexc, y= ~tpos/exc, stroke:=color[[m]]))
    }
    
    p + guide_axis('x', title="1-specificity") + guide_axis('y', title="sensitivity")
}
