glimp = function(formula, data, family, weights=NULL, tol=1e-10, max.iter=100, nlambda=100, lambda.min.ratio=100, lambda=NULL) {
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,predictor.names])
    n=nrow(x)
    
    meanx = vector()
    normx = vector()

    for (k in 1:ncol(x)) {
        meanx = c(meanx, mean(x[,k]))
        normx = c(normx, sqrt(sum((x[,k]-meanx[k])**2)))
        x[,k] = (x[,k]-meanx[k])/normx[k]
    }
    
    x = cbind(rep(1,nrow(x)), x)

    s = svd(x)   #  if you don't know what svd is, you should!  It's great.
    F = s$u  %*% diag(1/s$d)  %*%  t(s$u)
    x = F%*%x
    #pY = F%*%z
    #fit = lars(pX, pY)   #  You could replace "lars" with your favorite sparse regression function.  I have tried 
    
    if (is.null(lambda)) {
        lmax = max(abs(cor(x[,-1],y))) * sqrt(mean((y-mean(y))**2))
        ll = seq(from=5*lmax, to=lmax/lambda.min.ratio, length.out=nlambda)
    } else {        
        ll = as.vector(lambda)
    }

    eps = 1e-5
    eps.inv = log(eps) - log(1-eps)
    b = matrix(0, ncol(x), 1)
    b[1] = log(mean(y)) - log(1-mean(y))

    beta = list()

    for (j in 1:length(ll)) {
        l = ll[j]
        if (j>1) {b=beta[[j-1]]}  

        eta = x %*% b
        fitted = ifelse(eta<eps.inv, eps, ifelse(eta>-eps.inv, 1-eps, exp(eta)/(1+exp(eta))))
        w = as.vector(fitted*(1-fitted))

        obj.old = 0
        iter=0
        finished = FALSE

        while (finished==FALSE) {
            #print(fitted)
            #print(w)
    
            #z = as.matrix((y-fitted)/w + eta, nrow(x), 1)
            #b = solve(t(x) %*% diag(w) %*% x) %*% t(x) %*% diag(w) %*% z
            #print(b)
            for (k in 2:length(b)) {
                #print(w)
                z = (y-fitted)/w + x[,k]*b[k]
                
                z = F%*%z

                b[k] = lsfit(x=as.matrix(x[,k], nrow(x), 1), y=as.matrix(z, nrow(x), 1), wt=as.vector(w), intercept=TRUE)$coef[2]
                #b[k] = sum(w*(z-mean(z))*x[,k]) / sum(w*x[,k]**2)
                b[k] = S(b[k], l*sqrt(n)) 
            
                eta = x %*% b
                #print(eta)
                fitted = ifelse(eta<eps.inv, eps, ifelse(eta>-eps.inv, 1-eps, exp(eta) / (1+exp(eta))))
                #fitted = as.vector(exp(eta) / (1+exp(eta)))
                #fitted = ifelse(fitted<eps, eps, ifelse(fitted>1-eps, 1-eps, fitted))
                w = fitted*(1-fitted)
            }
            #print(fitted)
            #print(w)
            z = (y-fitted)/w + x[,1]*b[1]
            z = F%*%z
            b[1] = mean(z)
    
            #print(z)
            #print(b)
    
            eta = x %*% b
            fitted = ifelse(eta<eps.inv, eps, ifelse(eta>-eps.inv, 1-eps, exp(eta)/(1+exp(eta))))
            #fitted = as.vector(exp(eta) / (1+exp(eta)))
            #fitted = ifelse(fitted<eps, eps, ifelse(fitted>1-eps, 1-eps, fitted))
            w = as.vector(fitted*(1-fitted))
    
            #print(eta)            
    
            obj = sum(w*(y*eta - (1+exp(eta)))) #+ l*sum(abs(b[-1]))
            
            iter = iter+1
            cat(paste("obj=", obj, ", obj.old=", obj.old, "\n", sep=""))
            if (abs(obj-obj.old)<tol || iter>=max.iter) {finished = TRUE}
            obj.old = obj
        }
    
        cat(paste("Iterations: ", iter, "\n", sep=""))
        beta[[j]] = b
    }

    for (i in 1:length(beta)) {
        beta[[i]][-1] = beta[[i]][-1] / normx
        beta[[i]][1] = beta[[i]][1] - sum(beta[[i]][-1]*meanx)

        rownames(beta[[i]]) = c("(Intercept)", predictor.names)
        beta[[i]] = Matrix(beta[[i]])
    }

	return(list(beta=beta, meanx=meanx, normx=normx, x=x, lambda=ll))
}
 
    
penalty = function(alpha, beta, lambda) {
    lambda * (alpha * sum(abs(beta)) + (1-alpha) * sum(beta**2) / 2)
}


S = function(z, gamma) {
    sign(z) * max(abs(z) - gamma, 0)
}


logistic = function(formula, data, family, weights=NULL, tol=1e-10, max.iter=100) {
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,predictor.names])
    n=nrow(x)
    
    meanx = vector()
    normx = vector()

    for (k in 1:ncol(x)) {
        meanx = c(meanx, mean(x[,k]))
        normx = c(normx, sqrt(sum((x[,k]-meanx[k])**2)))
        x[,k] = (x[,k]-meanx[k])/normx[k]
    }
    
    x = cbind(rep(1,nrow(x)), x)
    
    eps = 1e-5
    eps.inv = log(eps) - log(1-eps)
    b = matrix(0, ncol(x), 1)
    b[1] = log(mean(y)) - log(1-mean(y))

    eta = x %*% b
    fitted = ifelse(eta<eps.inv, eps, ifelse(eta>-eps.inv, 1-eps, exp(eta)/(1+exp(eta))))
    w = as.vector(fitted*(1-fitted))

    obj.old = 0
    iter=0
    finished = FALSE

    while (finished==FALSE) {
        #print(fitted)
        #print(w)

        #z = as.matrix((y-fitted)/w + eta, nrow(x), 1)
        #b = solve(t(x) %*% diag(w) %*% x) %*% t(x) %*% diag(w) %*% z
        #print(b)
        for (k in 2:length(b)) {
            #print(w)
            z = (y-fitted)/w + x[,k]*b[k]
            b[k] = lsfit(x=as.matrix(x[,k], nrow(x), 1), y=as.matrix(z, nrow(x), 1), wt=as.vector(w), intercept=TRUE)$coef[2]
            #b[k] = sum(w*(z-mean(z))*x[,k]) / sum(w*x[,k]**2)
            #b[k] = S(sum(w*(z-mean(z))*x[,k]) / sum(, l*sqrt(n)) 
        
            eta = x %*% b
            #print(eta)
            fitted = ifelse(eta<eps.inv, eps, ifelse(eta>-eps.inv, 1-eps, exp(eta) / (1+exp(eta))))
            #fitted = as.vector(exp(eta) / (1+exp(eta)))
            #fitted = ifelse(fitted<eps, eps, ifelse(fitted>1-eps, 1-eps, fitted))
            w = fitted*(1-fitted)                     
        }
        #print(fitted)
        #print(w)
        z = (y-fitted)/w + x[,1]*b[1]
        b[1] = mean(z)

        #print(z)
        #print(b)

        eta = x %*% b
        fitted = ifelse(eta<eps.inv, eps, ifelse(eta>-eps.inv, 1-eps, exp(eta)/(1+exp(eta))))
        #fitted = as.vector(exp(eta) / (1+exp(eta)))
        #fitted = ifelse(fitted<eps, eps, ifelse(fitted>1-eps, 1-eps, fitted))
        w = as.vector(fitted*(1-fitted))

        #print(eta)            

        obj = sum(w*(y*eta - (1+exp(eta)))) #+ l*sum(abs(b[-1]))
        
        iter = iter+1
        cat(paste("obj=", obj, ", obj.old=", obj.old, "\n", sep=""))
        if (abs(obj-obj.old)<tol || iter>=max.iter) {finished = TRUE}
        obj.old = obj
    }
    
    cat(paste("Iterations: ", iter, "\n", sep=""))
    beta = b
    
    beta[-1] = beta[-1] / normx
    beta[1] = beta[1] - sum(beta[-1]*meanx)

    #rownames(beta) = c("(Intercept)", predictor.names)
    beta = Matrix(beta)

	return(list(beta=beta, meanx=meanx, normx=normx, x=x, fitted=fitted))
}



lasso = function(formula, data, family, weights=NULL, tol=1e-10, max.iter=100, nlambda=100, lambda.min.ratio=100, lambda=NULL) {
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,predictor.names])
    n=nrow(x)
    
    meanx = vector()
    normx = vector()
    ssx = vector()
    for (k in 1:ncol(x)) {
        meanx = c(meanx, mean(x[,k]))
        normx = c(normx, sqrt(sum((x[,k]-meanx[k])**2)))
        x[,k] = (x[,k]-meanx[k])/normx[k]
    }
    
    x = cbind(rep(1,nrow(x)), x)
    
    if (is.null(lambda)) {
        lmax = max(abs(cor(x[,-1],y))) * sqrt(mean((y-mean(y))**2))
        ll = seq(from=lmax, to=lmax/lambda.min.ratio, length.out=nlambda)
    } else {        
        ll = as.vector(lambda)
    }
    
    b0 = mean(y)
    b = matrix(0, ncol(x), 1)
    b[1]=b0
	
    beta = list()

    for (j in 1:length(ll)) {
        l = ll[j]
        if (j>1) {b=beta[[j-1]]}  

        fitted = x %*% b
        obj.old = 0
        iter=0
        finished = FALSE

        while (finished==FALSE) {
            for (k in 2:length(b)) {
                partial = y-fitted + x[,k]*b[k]
                b[k] = S(sum((partial-mean(partial))*x[,k]), l*sqrt(n))
                fitted = x %*% b                
            }

            partial = y-fitted + x[,1]*b[1]
            b[1] = mean(partial)
            fitted = x %*% b 
            
            obj = mean((y-fitted)**2) + l*sum(abs(b[-1]))
            
            iter = iter+1
            if (abs(obj-obj.old)<tol || iter>=max.iter) {finished = TRUE}
            obj.old = obj
        }
        
        cat(paste("Iterations: ", iter, "\n", sep=""))
        beta[[j]] = b
    }
    
    for (i in 1:length(beta)) {
        beta[[i]][-1] = beta[[i]][-1] / normx
        beta[[i]][1] = beta[[i]][1] - sum(beta[[i]][-1]*meanx)

        rownames(beta[[i]]) = c("(Intercept)", predictor.names)
        beta[[i]] = Matrix(beta[[i]])
    }

	return(list(beta=beta, meanx=meanx, normx=normx, x=x, lambda=ll))
}
