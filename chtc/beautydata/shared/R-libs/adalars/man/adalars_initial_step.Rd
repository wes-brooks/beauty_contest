\name{adalars_initial_step}
\alias{adalars_initial_step}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Get the intial coefficient estimates for all of the predictor variables
%%  ~~function to do ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
adalars_initial_step(formula, data, left = -Inf, right = Inf)
}
%- maybe also 'usage' for other objects documented here.
\arguments{
  \item{formula}{
%%     ~~Describe \code{formula} here~~
}
  \item{data}{
%%     ~~Describe \code{data} here~~
}
  \item{left}{
%%     ~~Describe \code{left} here~~
}
  \item{right}{
%%     ~~Describe \code{right} here~~
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
function(formula, data, left=-Inf, right=Inf) {
    #Create the object that will hold the output
    wrap = list()
    wrap[['formula']] = as.formula(formula)
    
    #Pull out the relevant data
    response.name = rownames(attr(terms(formula), 'factors'))[1]
    predictor.names = attr(terms(formula), 'term.labels')
    
    #Drop any rows with NA values
    model.data = data[,c(response.name, predictor.names)]
    na.rows = (which(is.na(model.data))-1) \%\% dim(model.data)[1] + 1
    if (length(na.rows)>0)
        model.data = model.data[-na.rows,]
    wrap[['data']] = model.data
    
    #Make the call to censReg
    wrap[['model']] = censReg(formula=formula, data=model.data, left=left, right=right)
    
    #Include some additional data in the wrapped object:
    wrap[['logSigma']] = wrap[['model']]$estimate[['logSigma']]
    wrap[['coef']] = wrap[['model']]$estimate[1:(length(predictor.names)+1)]
    wrap[['x']] = as.matrix(cbind(rep(1,dim(model.data)[1]), model.data[,-1]))
    wrap[['actual']] = model.data[,response.name]
    wrap[['fitted']] = wrap[['x']] \%*\% as.matrix(wrap[['coef']])
    wrap[['latent']] = ifelse(wrap[['actual']]>=right, wrap[['fitted']], ifelse(wrap[['actual']]<=left, wrap[['fitted']], wrap[['actual']]))
    
    return(wrap)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
