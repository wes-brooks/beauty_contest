galogistic_monitor <-
function(obj, data, output) {
    minEval = min(obj$evaluations, na.rm=TRUE)
    filter = which(obj$evaluations == minEval)
    bestObjectCount = sum(rep(1, obj$popSize)[filter])
    
    # ok, deal with the situation that more than one object is best
    if (bestObjectCount > 1) {
        bestSolution = obj$population[filter,][1,]
    } else {
        bestSolution = obj$population[filter,]
    }
    outputBest = paste(obj$iter, " #selected=", sum(bestSolution), " Best (Error=", minEval, "): ", sep="")
    
    selected = as.logical(bestSolution)
    out.col = which(colnames(data)==output)
    selected = paste(colnames(data[,-out.col][,selected]), collapse=", ")
    
    outputBest = paste(outputBest, selected, "\n")
    cat(outputBest)
}
