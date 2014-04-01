evalAICc <-
function(chromosome=c(), data, output) {
    returnVal = Inf
    minLV = 2
    if (sum(chromosome) >= minLV) {
        #Extract the selected variables, create the model formula and fit the model
        out.col = which(names(data)==output)
        selected = cbind(output=data[,output], data[,-out.col][,chromosome==1])
        f = as.formula("output~.")
        
        model = lm(f, data=selected)
        
        #Evaluate the model on the basis of the AICc:
        n = nrow(selected)
        df = summary(model)[['fstatistic']][['numdf']]        
        returnVal = AIC(model) + 2*df*(df+1)/(n-df-1)
    }
    if (is.na(returnVal)) { returnVal=Inf }
    return(returnVal)
}
