\name{spls.wrap}
\alias{spls.wrap}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Build an spls model with shrinkage and selection by the LASSO.
}
\description{
Build an spls model with shrinkage and selection by the LASSO.
}
\usage{
spls.wrap(x, y, K = NULL, eta = seq(0.05, 0.95, 0.05), kappa = 0.5, select = "pls2", fit = "simpls", scale.x = TRUE, scale.y = FALSE, eps = 1e-04, maxstep = 100, trace = FALSE)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{x}{
%%     ~~Describe \code{x} here~~
}
  \item{y}{
%%     ~~Describe \code{y} here~~
}
  \item{K}{
%%     ~~Describe \code{K} here~~
}
  \item{eta}{
%%     ~~Describe \code{eta} here~~
}
  \item{kappa}{
%%     ~~Describe \code{kappa} here~~
}
  \item{select}{
%%     ~~Describe \code{select} here~~
}
  \item{fit}{
%%     ~~Describe \code{fit} here~~
}
  \item{scale.x}{
%%     ~~Describe \code{scale.x} here~~
}
  \item{scale.y}{
%%     ~~Describe \code{scale.y} here~~
}
  \item{eps}{
%%     ~~Describe \code{eps} here~~
}
  \item{maxstep}{
%%     ~~Describe \code{maxstep} here~~
}
  \item{trace}{
%%     ~~Describe \code{trace} here~~
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
function (x, y, K = NULL, eta = seq(0.05, 0.95, 0.05), kappa = 0.5, 
    select = "pls2", fit = "simpls", scale.x = TRUE, scale.y = FALSE, 
    eps = 1e-04, maxstep = 100, trace = FALSE) 
{
    result = list()
    class(result) = "spls.wrap"
    if (is.null(K)) {
        max.K = min(ncol(x), floor(nrow(x)/10))
        K = 1:max.K
    }
    cv = cv.spls(x = x, y = y, K = K, eta = eta, fit = fit, select = select, 
        scale.x = scale.x, scale.y = scale.y)
    m = spls(x = x, y = y, K = cv$K.opt, eta = cv$eta.opt, kappa = kappa, 
        select = select, fit = fit, scale.x = scale.x, scale.y = scale.y, 
        eps = eps, maxstep = maxstep, trace = trace)
    ci = ci.spls(m, plot.it = FALSE)
    coef = correct.spls(ci)
    result[["coef"]] = coef
    result[["vars"]] = rownames(coef)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
