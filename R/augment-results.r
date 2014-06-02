#Create a data.frame for each beach that is the original data augmented with predictions from all 14 methods.
for (b in names(beaches)) {
    df = read.csv(beaches[[b]][['file']])
    for (m in methods) {
        if (m %in% c("adalasso-weighted", "adalasso-unweighted")) {
            colnames(results[[b]][[m]][['res']]) = c("predicted","actual","threshold","fold","tpos","tneg","fpos","fneg")
        }
        #Add the predicted values to the dataset:
        tryCatch(expr={
                    #Sort the predictions by fold to match the original order of the data:
                    pred = results[[b]][[m]][['res']][['predicted']]
                    pred = pred[order(results[[b]][[m]][['res']][['fold']])]
                    
                    df=cbind(df, m=pred)
                    colnames(df)[ncol(df)] = paste(m, "-predicted", sep="")
                },
                error = function(e) {print(e); print(b); print(m)}
        )
        
    }
    assign(b, df)
}