\name{galogistic}
\alias{galogistic}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Fit a linear model, using the genetic algorithm for variable selection.
}
\description{
Fit a linear model, using the genetic algorithm for variable selection.
}
\usage{
galogistic(formula, data, population = 200, generations = 100, mutateRate = 0.02, zeroOneRatio = 10, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{formula}{
%%     ~~Describe \code{formula} here~~
}
  \item{data}{
%%     ~~Describe \code{data} here~~
}
  \item{population}{
%%     ~~Describe \code{population} here~~
}
  \item{generations}{
%%     ~~Describe \code{generations} here~~
}
  \item{mutateRate}{
%%     ~~Describe \code{mutateRate} here~~
}
  \item{zeroOneRatio}{
%%     ~~Describe \code{zeroOneRatio} here~~
}
  \item{\dots}{
%%     ~~Describe \code{\dots} here~~
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
Wesley Brooks
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
function (formula, data, population = 200, generations = 100, 
    mutateRate = 0.02, zeroOneRatio = 10, ...) 
{
    result = list()
    class(result) = "adalasso"
    result[["formula"]] = as.formula(formula, env = data)
    na.rows = (which(is.na(data)) - 1)\%\%dim(data)[1] + 1
    if (length(na.rows) > 0) 
        data = data[-na.rows, ]
    m = ncol(data)
    n = nrow(data)
    response.name = rownames(attr(terms(formula, data = data), 
        "factors"))[1]
    predictor.names = attr(terms(formula, data = data), "term.labels")
    response.col = which(names(data) == response.name)
    result[["response"]] = response.name
    result[["predictors"]] = predictor.names
    f = as.formula(paste(paste(response.name, "~", sep = ""), 
        paste(predictor.names, collapse = "+"), sep = ""))
    y = as.matrix(data[, response.col])
    x = as.matrix(data[, -response.col])
    m = ncol(data) - 1
    result[["ga"]] = rbga.bin(size = m, zeroToOneRatio = zeroOneRatio, 
        evalFunc = evalBIC, monitorFunc = monitor, mutationChance = mutateRate, 
        popSize = population, iters = generations, verbose = TRUE)
    indx = which.min(result[["ga"]]$evaluations)
    indiv = as.logical(drop(result[["ga"]]$population[indx, ]))
    result[["vars"]] = predictor.names[indiv]
    result[["formula"]] = as.formula(paste(response.name, "~", 
        paste(result[["vars"]], collapse = "+"), sep = ""))
    result[["model"]] = lm(formula = result[["formula"]], data = data)
    class(result) = "galm"
    result
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
