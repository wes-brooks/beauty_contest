censReg_step <-
function(formula, data, left=-Inf, right=Inf) {
    #Create the object that will hold the output
    wrap = list()
    wrap[['formula']] = as.formula(formula)
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    #Drop any rows with NA values
    model.data = data[,c(response.name, predictor.names)]
    na.rows = (which(is.na(model.data))-1) %% dim(model.data)[1] + 1
    if (length(na.rows)>0)
        model.data = model.data[-na.rows,]
    wrap[['data']] = model.data
    
    #Make the call to censReg
    wrap[['model']] = censReg(formula=formula, data=model.data, left=left, right=right)
    
    #Include some additional data in the wrapped object:
    wrap[['logSigma']] = wrap[['model']]$estimate[['logSigma']]
    wrap[['coef']] = wrap[['model']]$estimate[1:(length(predictor.names)+1)]
    wrap[['x']] = as.matrix(cbind(rep(1,dim(model.data)[1]), model.data[,-1]))
    wrap[['actual']] = model.data[,response.name]
    wrap[['fitted']] = wrap[['x']] %*% as.matrix(wrap[['coef']])
    wrap[['latent']] = sapply(1:length(wrap[['actual']]), function(x) {ifelse(wrap[['actual']][x]<=left, min(wrap[['fitted']][x], left), ifelse(wrap[['actual']][x]>=right, max(wrap[['fitted']][x], right), wrap[['actual']][x]))})
    
    return(wrap)
}

