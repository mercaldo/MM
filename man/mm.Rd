\name{mm}
\alias{mm}
\title{
Fit Marginalized Transition and/or Latent Variable Models
}
\description{
Fit a marginalzed transition and/or latent variable models (mTLV) as described by Schildcrout and Heagerty 2007.  
}
\usage{
mm(mean.formula, lv.formula = NULL, t.formula = NULL, id, data,
   inits = NULL, offset = 0, q = 10, step.max = 1, step.tol = 1e-06, hess.eps = 1e-07, 
   verbose = FALSE,iter.lim=100)
}
\arguments{
  \item{mean.formula}{ Mean model formula in which a binary variable is regressed on covariates.}
  \item{lv.formula}{ Latent variable model formula (right hand side only) }
  \item{t.formula}{Transition model formula (right hand side only) }
  \item{id}{ a vector of cluster identifiers (it should be the same length nrow(data)).}
  \item{data}{ a required data frame }
  \item{inits}{an optional vector for initial values for marginal mean parameters and all dependence parameters. If NULL, initial values will be automatically generated.}
  \item{offset}{an optional offset term.}
  \item{q}{a scalar to denote the number of quadrature points used for GH numerical integration.}
  \item{step.max}{a scalar.}
  \item{step.tol}{a scalar.}
  \item{hess.eps}{a scalar.}
  \item{verbose}{an indicator if model output should be printed to the screen during maximization (or minimization of negative log-likelihood).}
  \item{iter.lim}{a scalar to denote the maximum iteration limit. Default value is 100.}
}

\value{
This function returns marginal mean (beta) and log-transformed dependence parameters (alpha) along with model-based and empirical covariance matricies. }

\author{ Nathaniel Mercaldo }

\seealso{
\code{\link{MMLongit}}
}

\examples{
\dontrun{
data(datrand)
fit <- mm(Y~time*binary, t.formula=~1, data=datrand, id=id, step.max=4, verbose=FALSE)}
}

