\name{predict.adalasso}
\alias{predict.adalasso}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Make predictions from an adalasso model
}
\description{
Make predictions from an adalasso model
}
\usage{
predict.adalasso(object, newx)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{object}{
%%     ~~Describe \code{object} here~~
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
function (object, newx) 
{
    pred.data = as.matrix(newx)
    print(paste("Predictiing with s=", object[["lars"]][["lambda.index"]], 
        sep = ""))
    return(predict.lars(object[["lars"]][["model"]], newx = pred.data, 
        type = "fit", s = object[["lars"]][["lambda.index"]], 
        mode = "step")$fit)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
