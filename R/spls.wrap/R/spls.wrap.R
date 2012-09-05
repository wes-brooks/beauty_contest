spls.wrap <-
function(formula, data, K=NULL, eta=seq(0.1,0.9,0.05), kappa=0.5, select="pls2", fit="simpls", eps=1e-4, maxstep=100, trace=FALSE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "spls.wrap"
    
    #Drop any rows with NA values
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    
    p = ncol(data)
    n = nrow(data)

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,-response.col])
    x.orig = x
    
    #Maximum number of predictor variables:
    p = ncol(x)
    
    meanx = vector()
    normx=vector()
    for (k in 1:p) {
        meanx = c(meanx, mean(x[,k]))
        normx = c(normx, sqrt(sum((x[,k]-meanx[k])**2)))
        x[,k] = (x[,k]-meanx[k])/normx[k]
    }
    
    if (is.null(K)) {
        max.K = min(ncol(x), floor(nrow(x)/10))
        K = 1:max.K
    }
    
    cv = cv.spls(x=x, y=y, K=K, eta=eta, fit=fit, select=select, scale.x=FALSE, scale.y=FALSE, plot.it=FALSE)
    m = spls(x=x, y=y, K=cv$K.opt, eta=cv$eta.opt, kappa=kappa, select=select, fit=fit, scale.x=FALSE, scale.y=FALSE, eps=eps, maxstep=maxstep, trace=trace)
    ci = ci.spls(m, plot.it=FALSE)
    coef = correct.spls(ci, plot.it=FALSE)
    
    result[['Intercept']] = as.numeric(m$mu)
    result[['meanx']] = meanx
    result[['normx']] = normx
    
    coef = coef / normx
    result[['Intercept']] = result[['Intercept']] - sum(coef*meanx)
    
    result[['coef']] = coef    
    
    result[['fitted']] = result[['Intercept']] + x.orig %*% coef
    result[['actual']] = y
    result[['residuals']] = result[['actual']] - result[['fitted']] 

    result[['vars']] = predictor.names[which(abs(coef)>0)]
    
    return(result)
}
