evalBIC_logistic <-
function(chromosome=c(), data, output, family, weights) {
    returnVal = Inf
    minLV = 2
    if (sum(chromosome) >= minLV) {
        #Extract the selected variables, create the model formula and fit the model
        out.col = which(colnames(data)==output)
        selected = cbind(output=data[,output], data[,-out.col][,chromosome==1])
        f = as.formula("output~.")
        model = glm(f, data=selected, family, weights)
        
        #Evaluate the model on the basis of the BIC:
        n = nrow(selected)
        returnVal = AIC(model, k=log(n))
    }
    return(returnVal)
}
