spls.wrap <-
function(formula, data, K=NULL, eta=seq(0.1,0.9,0.05), kappa=0.5, select="pls2", fit="simpls", eps=1e-4, maxstep=100, trace=FALSE, selectvars=FALSE) {
    #Create the object that will hold the output
    result = list()
    class(result) = "spls.wrap"
    
    #Drop any rows with NA values
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0) {
        print(paste("rows with nas: ", paste(na.rows, collapse=','), sep=''))
        data = data[-na.rows,]
    }
    
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
        norm = sqrt(sum((x[,k]-meanx[k])**2))
        if (norm > 0) {
            normx = c(normx, norm)
            x[,k] = (x[,k]-meanx[k])/norm
        } else {
            normx = c(normx, Inf)
        }
    }
    
    if (is.null(K)) {
        max.K = min(ncol(x), floor(nrow(x)/10))
        K = 1:max.K
    }
    
    cv = cv.spls(x=x, y=y, K=K, eta=eta, fit=fit, select=select, scale.x=FALSE, scale.y=FALSE, plot.it=FALSE)
    m = spls(x=x, y=y, K=cv$K.opt, eta=cv$eta.opt, kappa=kappa, select=select, fit=fit, scale.x=FALSE, scale.y=FALSE, eps=eps, maxstep=maxstep, trace=trace)
    ci = try(ci.spls(m, plot.it=FALSE))
    if (class(ci)=='try-error') {
        print("error! x:")
        print(x)
        coef=coef(m)
    } else {
        coef = correct.spls(ci, plot.it=FALSE)
    }
    
    result[['vars']] = predictor.names[which(abs(coef)>0)]
        
    if (selectvars==TRUE) {
        variables = paste(result[['vars']], collapse="+")
        f = as.formula(paste(response.name, "~", variables, sep=""))
        m = lm(formula=f, data=data)
        coef = matrix(0, length(result[['predictors']]), 1)
        for (v in names(m$coef[-1])) {
            i = which(result[['predictors']]==v)
            coef[i,1] = m$coef[[v]]
        }
        result[['Intercept']] = m$coef[["(Intercept)"]]
        result[['fitted']] = m$fitted
    } else {
        result[['meanx']] = meanx
        result[['normx']] = normx  
        coef = coef / normx
        result[['Intercept']] = as.numeric(m$mu) - sum(coef*meanx)
        result[['fitted']] = result[['Intercept']] + x.orig %*% coef
    }    
    
    result[['coef']] = Matrix(coef)    
    result[['actual']] = y
    result[['residuals']] = result[['actual']] - result[['fitted']]    
    
    return(result)
}
