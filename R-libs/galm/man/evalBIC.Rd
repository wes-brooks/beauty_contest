\name{evalBIC}
\alias{evalBIC}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Evaluate the fitness of a genalg "chromosome"
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
evalBIC(chromosome = c())
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{chromosome}{
%%     ~~Describe \code{chromosome} here~~
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
function (chromosome = c()) 
{
    returnVal = Inf
    minLV = 2
    if (sum(chromosome) >= minLV) {
        out.col = which(names(data) == output)
        selected = cbind(output = data[, output], data[, -out.col][, 
            chromosome == 1])
        f = as.formula("output~.")
        model = lm(f, data = selected)
        n = nrow(selected)
        returnVal = AIC(model, k = log(n))
    }
    return(returnVal)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
