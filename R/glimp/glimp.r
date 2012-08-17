glimp = function(formula, data, family, weights=NULL, tol=1e-5, max.iter=100) {
    #Create the object that will hold the output
    result = list()
    class(result) = "glimp"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    result[['data']] = data

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,predictor.names])
    #x = scale(x, center=TRUE, scale=TRUE)
    x = cbind(rep(1,nrow(x)), x)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
    
    #Define some constants
    eps = 1e-5
    lambda.ratio = 100
    lmax = max(abs(cor(x[,-1],y))) / 2.28
    l = seq(from=lmax/lambda.ratio, to=lmax, length.out=lambda.ratio)
    alpha = 1
    b0 = log(mean(y)/(1-mean(y)))
    b = matrix(rnorm(n=ncol(x)), ncol(x), 1)
    b[1]=b0
    
    lambda = 0
    print(lambda)
    
    if (family=='binomial') {
        eta = x %*% b
        fitted = exp(eta) / (1+exp(eta))
        
        obj.old = 0
        iter=0
        finished = FALSE
        
        while (finished == FALSE) {
            print(b)
            b.new = b
            W = as.vector(fitted * (1-fitted))
            z = eta + (y-fitted) / (fitted*(1-fitted))
            #b = lsfit(x=x, y=z, wt=W, intercept=FALSE)$coef
            
            for (k in 2:length(b)) {
                #z.partial = x[,k]*b[k]
                #b.new[k] = S(sum(W*x[,k]*z.partial), lambda*alpha) / (sum(W*x[,k]**2) + lambda*alpha)
                b[k] = lsfit(y=z, x=x[,k], wt=W, intercept=FALSE)$coef
                
                eta = x %*% b
	            fitted = exp(eta) / (1+exp(eta))
	            z = eta + (y-fitted) / (fitted*(1-fitted))
	            W = as.vector(fitted * (1-fitted))
            }
			b[1] = lsfit(y=z, x=x[,1], wt=W, intercept=FALSE)$coef			
			eta = x %*% b
			fitted = exp(eta) / (1+exp(eta))
			z = eta + (y-fitted) / (fitted*(1-fitted))
			W = as.vector(fitted * (1-fitted))
			
            #z.partial = x[,1]*b[1]
            #b.new[1] = sum(W*x[,1]*z.partial) / (sum(W*x[,1]))
            #b = b.new
        
            #eta = x %*% b
            #fitted = exp(eta) / (1+exp(eta))
        
            lq = -0.5 * mean(W * (z - x%*%b)**2)
            obj = -lq + penalty(alpha, b[-1], lambda)  
            
            iter = iter + 1
            if (abs(obj - obj.old) < tol || iter>=max.iter) {finished = TRUE}
            obj.old = obj
        }
        
        cat(paste("Iterations: ", iter, "\n", sep=""))
        return(b)
    }
}
 
    
penalty = function(alpha, beta, lambda) {
    lambda * (alpha * sum(abs(beta)) + (1-alpha) * sum(beta**2) / 2)
}


S = function(z, gamma) {
    sign(z) * max(abs(z) - gamma, 0)
}


logistic = function(formula, data, family, weights=NULL, tol=1e-10, max.iter=100) {
    #Create the object that will hold the output
    result = list()
    class(result) = "glimp"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    result[['data']] = data

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,predictor.names])
    #x = scale(x, center=TRUE, scale=FALSE)
    #meanx = attr(x, "scaled:center")
    #normx = 1 / attr(x, "scaled:scale")
    
    x = cbind(rep(1,nrow(x)), x)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
    
    #Define some constants
    eps = 1e-5    
    
    if (family=='binomial') {
		fitted = ifelse(y<eps, eps, ifelse(y>1-eps,1-eps,y))
    	eta = log(fitted) - log(1-fitted)
    	W = as.vector(fitted * (1-fitted))
    	z = eta + (y-fitted) / (fitted*(1-fitted))
        
        obj.old = 0
        iter=0
        finished = FALSE
        
        while (finished==FALSE) {
            b = lsfit(x=x, y=z, wt=W, intercept=FALSE)$coef
            print(b)
            eta = x %*% b
			fitted = exp(eta) / (1+exp(eta))
			z = eta + (y-fitted) / (fitted*(1-fitted))
			W = as.vector(fitted * (1-fitted))
			
            lq = -0.5 * mean(W * (z - x%*%b)**2)
            obj = -lq #+ penalty(alpha, b[-1], lambda)  
            print(lq)
            
            iter = iter + 1
            if (abs(obj - obj.old)<tol || iter>=max.iter) {finished = TRUE}
            obj.old = obj
        }
        
        cat(paste("Iterations: ", iter, "\n", sep=""))
        return(b)
    }
}


lasso = function(formula, data, family, weights=NULL, tol=1e-10, max.iter=100, nlambda=100, lambda.min.ratio=1000, lambda=NULL) {
    #Create the object that will hold the output
    result = list()
    class(result) = "glimp"
    result[['formula']] = as.formula(formula, env=data)
    
    #Drop any rows with NA values
    data = data
    na.rows = (which(is.na(data))-1) %% dim(data)[1] + 1
    if (length(na.rows)>0)
        data = data[-na.rows,]
    result[['data']] = data

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    response.col = which(colnames(data)==response.name)
    
    y = as.matrix(data[,response.col])
    x = as.matrix(data[,predictor.names])
    x = scale(x, center=TRUE, scale=TRUE)
    meanx = attr(x, "scaled:center")
    scalex = attr(x, "scaled:scale")
    
    x = cbind(rep(1,nrow(x)), x)
    
    result[['response']] = response.name
    result[['predictors']] = predictor.names
    
    #Define some constants
    eps = 1e-5   
    if (is.null(lambda)) {
        lmax = max(abs(cor(x[,-1],y)))
        ll = seq(from=lmax, to=lmax/lambda.min.ratio, length.out=nlambda)
    } else {
        print(lambda)
        ll = as.vector(lambda)
    }
    alpha = 1
    b0 = mean(y)
    b = matrix(0, ncol(x), 1)
    b[1]=b0
	
    beta = list()

    for (j in 1:length(ll)) {
        l = ll[j]
        if (j>1) {
            b=beta[[j-1]]
            #b[1] = b[1] + sum(b[-1]*meanx)
            #b[-1] = b[-1] * scalex
        }  

        fitted = x %*% b
        obj.old = 0
        iter=0
        finished = FALSE

        while (finished==FALSE) {
            for (k in 2:length(b)) {
                partial = y-fitted + x[,k]*b[k]
                b[k] = S(sum(x[,k]*partial), l) / sum(x[,k]**2)
                fitted = x %*% b                
            }

            partial = y-fitted + x[,1]*b[1]
            b[1] = sum(x[,1]*partial) / sum(x[,1]**2)
            
            obj = 0.5*mean((y-fitted)**2) + l*sum(abs(b))
            
            iter = iter+1
            if (abs(obj - obj.old)<tol || iter>=max.iter) {finished = TRUE}
            obj.old = obj
        }
        
        cat(paste("Iterations: ", iter, "\n", sep=""))
        
        beta[[j]] = b

        #for (k in 2:length(b)) {       
        #    beta[[j]][k] = b[k] / scalex[k-1]
        #    beta[[j]][1] = b[1] - b[k]*meanx[k-1]
        #    b[1] = b[1] - sum(b[-1]/scalex * meanx)
        #}
    }

	return(list(beta=beta, meanx=meanx, scalex=scalex))
}
