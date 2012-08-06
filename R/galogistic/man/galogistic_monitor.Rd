\name{galogistic_monitor}
\alias{galogistic_monitor}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Monitor the process of the genetic algorithm by printing a summary at each step.
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
galogistic_monitor(obj)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{obj}{
%%     ~~Describe \code{obj} here~~
}
}
\details{
%%  ~~ If necessary, more details than the description above ~~
}
\value{
%%  ~Describe the value returned
%%  If it is a LIST, use
%%  \item{comp1 }{Description of 'comp1'}
%%  \item{comp2 }{Description of 'comp2'}
%% ...
}
\references{
%% ~put references to the literature/web site here ~
}
\author{
%%  ~~who you are~~
}
\note{
%%  ~~further notes~~
}

%% ~Make other sections like Warning with \section{Warning }{....} ~

\seealso{
%% ~~objects to See Also as \code{\link{help}}, ~~~
}
\examples{
##---- Should be DIRECTLY executable !! ----
##-- ==>  Define data, use random,
##--	or do  help(data=index)  for the standard data sets.

## The function is currently defined as
function (obj) 
{
    minEval = min(obj$evaluations)
    filter = obj$evaluations == minEval
    bestObjectCount = sum(rep(1, obj$popSize)[filter])
    if (bestObjectCount > 1) {
        bestSolution = obj$population[filter, ][1, ]
    }
    else {
        bestSolution = obj$population[filter, ]
    }
    outputBest = paste(obj$iter, " #selected=", sum(bestSolution), 
        " Best (Error=", minEval, "): ", sep = "")
    selected = as.logical(bestSolution)
    out.col = which(names(data) == output)
    selected = paste(names(data[, -out.col][, selected]), collapse = ", ")
    outputBest = paste(outputBest, selected, "\n")
    cat(outputBest)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
