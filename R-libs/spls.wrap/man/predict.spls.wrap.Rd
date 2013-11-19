\name{predict.spls.wrap}
\alias{predict.spls.wrap}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Make predictions from an spls.wrap model
}
\description{
Makes predictions from an spls.wrap model
}
\usage{
predict.spls.wrap(model, newx)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{model}{
%%     ~~Describe \code{model} here~~
}
  \item{newx}{
%%     ~~Describe \code{newx} here~~
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
function (model, newx) 
{
    n = nrow(newx)
    p = length(model[["coef"]])
    b = matrix(model[["coef"]], nrow = p, ncol = 1)
    x = matrix(newx, nrow = n, ncol = p)
    return(x \%*\% b)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
