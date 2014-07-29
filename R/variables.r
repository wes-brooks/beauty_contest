require(Matrix)

head = list()
varlist = list()

for (site in sites) {
    datafile = beaches[[site]][['file']]
    d = read.table(datafile, header=TRUE, sep=',')
    
    indx = which(!names(d) %in% c(beaches[[site]][['remove']], beaches[[site]][['target']]))
    head[[site]] = names(d)[indx]
    
    varlist[[site]] = sapply(methods, function(x) return(Matrix(0, nrow=nrow(d), ncol=length(indx))), simplify=FALSE)
    for (m in methods) 
        colnames(varlist[[site]][[m]]) = head[[site]]
}

for(site in sites) {
    for (m in methods) {
        for (i in 1:length(var_results[[site]][[m]])) {
            varlist[[site]][[m]][i, var_results[[site]][[m]][[i]]] = TRUE
        }
    }
}

for (site in sites) {
    vv = colnames(varlist[[site]][['adapt']])
    cat(paste("site: ", site, "\n", sep=""))
    cat(paste("auto: ", (1:length(vv))[-grep("beach", vv)] %>% length, "\n", sep=""))
    cat(paste("man: ", grep("beach", vv) %>% length, "\n", sep=""))
}