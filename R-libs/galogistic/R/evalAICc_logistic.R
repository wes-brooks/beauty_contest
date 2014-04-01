evalAICc_logistic <- function(chromosome=c(), data, output, family, weights) {
    returnVal = Inf
    minLV = 1
    if (sum(chromosome) >= minLV) {
        #Extract the selected variables, create the model formula and fit the model
        out.col = which(colnames(data)==output)
        selected = data.frame(output=data[,output], data[,-out.col][,chromosome==1])
        f = as.formula("output~.")

        model = glm(f, data=selected, family, weights)
        if ("glm.fit: algorithm did not converge" %in% names(warnings()) || "glm.fit: fitted probabilities numerically 0 or 1 occurred" %in% names(warnings())) {
            returnVal = Inf
        } else {
            #Evaluate the model on the basis of the BIC:
            n = nrow(selected)
            summ = summary(model)
            df = summ[['df.null']] - summ[['df.residual']]
    
            returnVal = AIC(model) + 2*df*(df+1)/(n-df-1)
        }
    }
    if (is.na(returnVal)) { returnVal = Inf }
    return(returnVal)
}
