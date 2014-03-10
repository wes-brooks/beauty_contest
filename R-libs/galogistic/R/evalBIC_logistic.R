evalBIC_logistic <-
function(chromosome=c(), data, output, family, weights) {
    returnVal = Inf
    minLV = 1
    if (sum(chromosome) >= minLV) {
        #Extract the selected variables, create the model formula and fit the model
        out.col = which(colnames(data)==output)
        selected = data.frame(output=data[,output], data[,-out.col][,chromosome==1])
        f = as.formula("output~.")
        returnVal = tryCatch(
		{
			model = glm(f, data=selected, family, weights)
			
			#Evaluate the model on the basis of the BIC:
			n = nrow(selected)            
			AIC(model, k=log(n))
		}, warning = function(w) {
			Inf
		})
    }
    return(returnVal)
}
