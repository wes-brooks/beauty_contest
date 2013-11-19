\name{adalasso}
\alias{adalasso}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Master function to use the adaptive lasso for shrinkage and selection in a generalized linear model
}
\description{
Master function to use the adaptive lasso for shrinkage and selection in a generalized linear model
}
\usage{
adalasso(formula, data, family, weights, max.iter = 20, tol = 1e-25, s = NULL)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{formula}{
The model formula
}
  \item{data}{
Model data frame
}
  \item{family}{
To which exponential-family distribution does the GLM belong?
}
  \item{weights}{
Observation weights
}
  \item{max.iter}{
How many times to iterate the adaptive-lasso cycle
}
  \item{tol}{
Tolerance for conversion
}
  \item{s}{
Values of the lasso tuning parameter at which to fit models
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
function (formula, data, family, weights, max.iter = 20, tol = 1e-25, 
    s = NULL) 
{
    result = list()
    class(result) = "adalasso"
    result[["formula"]] = as.formula(formula, env = data)
    model.data = data
    na.rows = (which(is.na(model.data)) - 1)\%\%dim(model.data)[1] + 
        1
    if (length(na.rows) > 0) 
        model.data = model.data[-na.rows, ]
    response.name = rownames(attr(terms(formula, data = data), 
        "factors"))[1]
    predictor.names = attr(terms(formula, data = data), "term.labels")
    response.col = which(names(model.data) == response.name)
    y = as.matrix(model.data[, response.col])
    x = as.matrix(model.data[, -response.col])
    result[["lasso"]] = lasso_step(y = y, x = x, family = family, 
        weights = weights, s = s)
    iter = 1
    change = tol + 1
    lambda.former = result[["lasso"]][["lambda"]]
    result[["lambda"]] = c(lambda.former)
    while (iter <= max.iter && change > tol) {
        cat(paste("Iteration: ", iter, "\n", sep = ""))
        f = as.formula(paste(paste(response.name, "~", sep = ""), 
            paste(result[["lasso"]][["vars"]], collapse = "+"), 
            sep = ""))
        result[["adapt"]] = adapt = adaptive_step(formula = f, 
            data = model.data, family = family, weights = weights)
        result[["lasso"]] = lasso_step(y = y, x = as.matrix(model.data[, 
            -response.col]), family = family, weights = weights, 
            adaptive.object = adapt, s = s)
        result[["lambda"]] = c(result[["lambda"]], result[["lasso"]][["lambda"]])
        change = abs(lambda.former - tail(result[["lambda"]], 
            1))
        lambda.former = tail(result[["lambda"]], 1)
        iter = iter + 1
        cat(paste("Change in lambda: ", change, "\n", sep = ""))
    }
    result[["iter"]] = iter - 1
    return(result)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
