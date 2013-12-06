\name{adalars_step}
\alias{adalars_step}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Uses the lars package to select variables based on the imputed observations that come out of the censReg step.
%%  ~~function to do ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
adalars_step(y, x)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{y}{
%%     ~~Describe \code{y} here~~
}
  \item{x}{
%%     ~~Describe \code{x} here~~
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
function(y, x) {
    result = list()
    
    p.max = min(dim(x)[2], dim(x)[1]-5)
    result[['cv']] = cv.model = cv.lars(y=y, x=x, type='lar', index=1:p.max, K=dim(x)[1])
    err.min = min(cv.model$cv)
    err.tol = err.min + cv.model$cv.error[which.min(cv.model$cv)]
    
    which.tol = which(cv.model$cv<err.tol)
    
    result[['lambda.index']] = lambda.index = min(which.tol)
    result[['model']] = model = lars(y=y, x=x, type='lar', max.steps=p.max)
    result[['fitted']] = predict.lars(model, newx=x, type='fit', s=lambda.index, mode='step')
    result[['vars']] = vars = names(which(model$beta[lambda.index,]>0))
    coefs = predict.lars(model, type='coefficients', s=lambda.index, mode='step')
    result[['coefs']] = coefs$coefficients[which(coefs$coefficients>0)]
    
    return(result)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
