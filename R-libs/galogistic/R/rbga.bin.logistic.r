rbga.bin.logistic = function(size=10, suggestions=NULL, popSize=200, iters=100, mutationChance=NA, elitism=NA, zeroToOneRatio=10, monitorFunc=NULL, evalFunc=NULL, showSettings=FALSE, verbose=FALSE, data, output, family, weights) {
    if (is.null(evalFunc)) {
        stop("A evaluation function must be provided. See the evalFunc parameter.")
    }
    vars = size
    if (is.na(mutationChance)) {
        mutationChance = 1/(vars + 1)
    }
    if (is.na(elitism)) {
        elitism = floor(popSize/5)
    }
    if (verbose) 
        cat("Testing the sanity of parameters...\n")
    if (popSize < 5) {
        stop("The population size must be at least 5.")
    }
    if (iters < 1) {
        stop("The number of iterations must be at least 1.")
    }
    if (!(elitism < popSize)) {
        stop("The population size must be greater than the elitism.")
    }
    if (showSettings) {
        if (verbose) cat("The start conditions:\n")
        result = list(size=size, suggestions=suggestions, 
            popSize=popSize, iters=iters, elitism=elitism, 
            mutationChance=mutationChance)
        class(result) = "rbga"
        cat(summary(result))
    }
    else {
        if (verbose) 
            cat("Not showing GA settings...\n")
    }
    if (vars > 0) {
        if (!is.null(suggestions)) {
            if (verbose) cat("Adding suggestions to first population...\n")
            population = matrix(nrow=popSize, ncol=vars)
            suggestionCount = dim(suggestions)[1]
            for (i in 1:suggestionCount) {
                population[i,] = suggestions[i,]
            }
            if (verbose) cat("Filling others with random values in the given domains...\n")
            for (child in (suggestionCount + 1):popSize) {
                population[child, ] = sample(c(rep(0, zeroToOneRatio), 1), vars, rep=TRUE)
                while (sum(population[child, ]) == 0) {
                  population[child, ] = sample(c(rep(0, zeroToOneRatio), 1), vars, rep=TRUE)
                }
            }
        }
        else {
            if (verbose) 
                cat("Starting with random values in the given domains...\n")
            population = matrix(nrow=popSize, ncol=vars)
            for (child in 1:popSize) {
                population[child,] = sample(c(rep(0, zeroToOneRatio), 1), vars, rep=TRUE)
                while (sum(population[child,]) == 0) {
                  population[child,] = sample(c(rep(0, zeroToOneRatio), 1), vars, rep=TRUE)
                }
            }
        }
        bestEvals = rep(NA, iters)
        meanEvals = rep(NA, iters)
        evalVals = rep(NA, popSize)
        for (iter in 1:iters) {
            if (verbose) 
                cat(paste("Starting iteration", iter, "\n"))
            if (verbose) 
                cat("Calucating evaluation values... ")
            for (object in 1:popSize) {
                if (is.na(evalVals[object])) {
                  evalVals[object] = evalFunc(population[object,], data=data, output=output, family=family, weights=weights)
                  if (verbose) 
                    cat(".")
                }
            }
            bestEvals[iter] = min(evalVals)
            meanEvals[iter] = mean(evalVals)
            if (verbose) 
                cat(" done.\n")
            if (!is.null(monitorFunc)) {
                if (verbose) 
                  cat("Sending current state to rgba.monitor()...\n")
                result = list(type="binary chromosome", size=size, 
                  popSize=popSize, iter=iter, iters=iters, 
                  population=population, elitism=elitism, 
                  mutationChance=mutationChance, evaluations=evalVals, 
                  best=bestEvals, mean=meanEvals)
                class(result) = "rbga"
                monitorFunc(result, output=output, data=data)
            }
            if (iter < iters) {
                if (verbose) 
                  cat("Creating next generation...\n")
                newPopulation = matrix(nrow = popSize, ncol = vars)
                newEvalVals = rep(NA, popSize)
                if (verbose) 
                  cat("  sorting results...\n")
                sortedEvaluations = sort(evalVals, index = TRUE)
                sortedPopulation = matrix(population[sortedEvaluations$ix,], ncol=vars)
                if (elitism > 0) {
                  if (verbose) cat("  applying elitism...\n")
                  newPopulation[1:elitism,] = sortedPopulation[1:elitism,]
                  newEvalVals[1:elitism] = sortedEvaluations$x[1:elitism]
                }
                if (vars > 1) {
                  if (verbose) 
                    cat("  applying crossover...\n")
                  for (child in (elitism + 1):popSize) {
                    parentProb = dnorm(1:popSize, mean=0, sd=(popSize/3))
                    parentIDs = sample(1:popSize, 2, prob=parentProb)
                    parents = sortedPopulation[parentIDs,]
                    crossOverPoint = sample(0:vars, 1)
                    if (crossOverPoint == 0) {
                      newPopulation[child,] = parents[2,]
                      newEvalVals[child] = sortedEvaluations$x[parentIDs[2]]
                    }
                    else if (crossOverPoint == vars) {
                      newPopulation[child,] = parents[1,]
                      newEvalVals[child] = sortedEvaluations$x[parentIDs[1]]
                    }
                    else {
                      newPopulation[child,] = c(parents[1,][1:crossOverPoint], parents[2,][(crossOverPoint+1):vars])
                      while (sum(newPopulation[child, ]) == 0) {
                        newPopulation[child,]=sample(c(rep(0, zeroToOneRatio), 1), vars, rep=TRUE)
                      }
                    }
                  }
                }
                else {
                  if (verbose) cat("  cannot crossover (#vars=1), using new randoms...\n")
                  newPopulation[(elitism+1):popSize,] = sortedPopulation[sample(1:popSize, popSize-elitism),]
                }
                population = newPopulation
                evalVals = newEvalVals
                if (mutationChance > 0) {
                  if (verbose) cat("  applying mutations... ")
                  mutationCount = 0
                  for (object in (elitism + 1):popSize) {
                    for (var in 1:vars) {
                      if (runif(1) < mutationChance) {
                        population[object, var] = sample(c(rep(0, zeroToOneRatio), 1), 1)
                        mutationCount = mutationCount + 1
                      }
                    }
                  }
                  if (verbose) cat(paste(mutationCount, "mutations applied\n"))
                }
            }
        }
    }
    result = list(type="binary chromosome", size=size, popSize=popSize, 
        iters=iters, suggestions=suggestions, population=population, 
        elitism=elitism, mutationChance=mutationChance, evaluations=evalVals, 
        best=bestEvals, mean=meanEvals)
    class(result) = "rbga"
    return(result)
}
