\name{adalars}
\alias{adalars}
%- Also NEED an '\alias' for EACH other topic documented here.
\title{
Iterate between the censReg step and the lars step in order to produce a final model.
%%  ~~function to do ... ~~
}
\description{
%%  ~~ A concise (1-5 lines) description of what the function does. ~~
}
\usage{
adalars(formula, data, left = -Inf, right = Inf, max.iter = 10, tol = 1e-25)
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
  \item{max.iter}{
%%     ~~Describe \code{max.iter} here~~
}
  \item{tol}{
%%     ~~Describe \code{tol} here~~
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
function(formula, data, left=-Inf, right=Inf, max.iter=10, tol=1e-25) {
    #Create the object that will hold the output
    result = list()
    result[['formula']] = as.formula(formula, env=data)

    #Pull out the relevant data
    response.name = rownames(attr(terms(formula, data=data), 'factors'))[1]
    predictor.names = attr(terms(formula, data=data), 'term.labels')
    
    #Drop any rows with NA values
    model.data = data
    na.rows = (which(is.na(model.data))-1) \%\% dim(model.data)[1] + 1
    if (length(na.rows)>0)
        model.data = model.data[-na.rows,]
        
    #Get the initial lasso estimate
    y = as.matrix(model.data[,1])
    x = as.matrix(model.data[,-1])
    result[['lars']] = censLars(y=y, x=x)
    
    #prepare for iteration
    iter = 1
    change = tol+1
    lambda.former = result[['lars']][['model']][['lambda']][result[['lars']][['lambda.index']]]
    result[['lambda']] = c(lambda.former)
    
    
    #Repeat until convergence
    while (iter<=max.iter && change>tol) {
        f = as.formula(paste(paste(response.name, "~", sep=''), paste(result[['lars']][['vars']], collapse='+'), sep=''), env=as.environment(model.data))
        result[['cens']] = cens = censReg_step(formula=f, data=model.data, left=left, right=right)
        response.col = which(names(model.data)==response.name)
        result[['lars']] = lars_step(y=as.matrix(result[['cens']][['latent']]), x=as.matrix(model.data[,-response.col]))
        result[['lambda']] = c(result[['lambda']], result[['lars']][['model']][['lambda']][result[['lars']][['lambda.index']]])
        
        change = abs(lambda.former - tail(result[['lambda']], 1))
        lambda.former = tail(result[['lambda']], 1)
        iter = iter+1
    }
    
    result[['iter']] = iter-1
    return(result)
  }
}
% Add one or more standard keywords, see file 'KEYWORDS' in the
% R documentation directory.
\keyword{ ~kwd1 }
\keyword{ ~kwd2 }% __ONLY ONE__ keyword per line
