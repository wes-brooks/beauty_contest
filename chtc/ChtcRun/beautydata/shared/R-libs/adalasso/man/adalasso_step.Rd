\name{adalasso_step}
\alias{adalasso_step}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
The glmnet step (shrinks and selects model coefficients) for adaptive lasso shrinkage and selection in a generalized linear model
}
\description{
The glmnet step (shrinks and selects model coefficients) for adaptive lasso shrinkage and selection in a generalized linear model
}
\usage{
adalasso_step(y, x, family, weights, adaptive.object = NULL, s = NULL, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{y}{
%%     ~~Describe \code{y} here~~
}
  \item{x}{
%%     ~~Describe \code{x} here~~
}
  \item{family}{
%%     ~~Describe \code{family} here~~
}
  \item{weights}{
%%     ~~Describe \code{weights} here~~
}
  \item{adaptive.object}{
%%     ~~Describe \code{adaptive.object} here~~
}
  \item{s}{
%%     ~~Describe \code{s} here~~
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
function (y, x, family, weights, adaptive.object = NULL, s = NULL, 
    ...) 
{
    result = list()
    m <- ncol(x)
    n <- nrow(x)
    one <- rep(1, n)
    result[["meanx"]] = (meanx <- drop(one \%*\% x)/n)
    x.centered <- scale(x, meanx, FALSE)
    normx <- sqrt(drop(one \%*\% (x.centered^2)))
    names(normx) <- NULL
    xs = x.centered
    for (k in 1:dim(x.centered)[2]) {
        if (normx[k] != 0) {
            xs[, k] = xs[, k]/normx[k]
        }
        else {
            xs[, k] = rep(0, dim(xs)[1])
            normx[k] = Inf
        }
    }
    if (is.null(adaptive.object)) {
        result[["coef.scale"]] = coef.scale = 1/normx
    }
    else {
        ada.weight = adaptive.object[["adaweight"]]
        for (k in 1:dim(x.centered)[2]) {
            if (!is.na(ada.weight[k])) {
                xs[, k] = xs[, k] * ada.weight[k]
            }
            else {
                xs[, k] = rep(0, dim(xs)[1])
                ada.weight[k] = 0
            }
        }
        result[["coef.scale"]] = coef.scale = ada.weight/normx
    }
    result[["model"]] = model = glmnet(x = xs, y = y, family = family, 
        weights = weights, lambda = s, ...)
    result[["cv.model"]] = cv.model = cv.glmnet(y = y, x = xs, 
        nfolds = dim(x)[1], family = family, weights = weights, 
        lambda = s, ...)
    result[["lambda"]] = lambda = cv.model$lambda.min
    nonzero = as.vector(predict(model, type = "nonzero", s = lambda))
    print(nonzero)
    coefs = coef(model, s = lambda)
    result[["coef"]] = as.list(coefs)[nonzero + 1]
    names(result[["coef"]]) = rownames(coefs)[nonzero + 1]
    result[["intercept"]] = intercept = coefs[1]
    result[["vars"]] = names(result[["coef"]])
    return(result)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
