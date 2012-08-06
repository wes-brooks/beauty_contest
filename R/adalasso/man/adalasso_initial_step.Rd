\name{adalasso_initial_step}
\alias{adalasso_initial_step}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
The first glm step uses each variable as a predictor, one at a time.
}
}
\description{
The first glm step uses each variable as a predictor, one at a time.
}
\usage{
adalasso_initial_step(formula, data, family, weights, ...)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{formula}{
%%     ~~Describe \code{formula} here~~
}
  \item{data}{
%%     ~~Describe \code{data} here~~
}
  \item{family}{
%%     ~~Describe \code{family} here~~
}
  \item{weights}{
%%     ~~Describe \code{weights} here~~
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
function (formula, data, family, weights, ...) 
{
    result <- list()
    response.name = rownames(attr(terms(formula, data = data), 
        "factors"))[1]
    predictor.names = attr(terms(formula, data = data), "term.labels")
    na.rows = (which(is.na(data)) - 1)\%\%dim(data)[1] + 1
    if (length(na.rows) > 0) 
        data = data[-na.rows, ]
    result[["data"]] = data
    result[["model"]] = model = glm(formula = formula, data = data, 
        family = family, weights = weights, ...)
    coefs = as.list(coef(model))
    coefs[["(Intercept)"]] = NULL
    adaweight = vector()
    for (name in names(data)[-which(names(data) == response.name)]) {
        if (name \%in\% predictor.names) {
            adaweight = c(adaweight, 1/coefs[[name]])
        }
        else {
            adaweight = c(adaweight, 1)
        }
    }
    result[["coefs"]] = coefs
    result[["adaweight"]] = adaweight
    return(result)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
