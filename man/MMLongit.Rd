\name{MMLongit}
\alias{MMLongit}
\title{ Function used to fit marginalized models. }
\description{ Internal function used to fit marginalized models.  See mm() for a more user friendly function.}
\usage{ MMLongit(params, id, X, Y, Xgam, Xsig, Q, offset = 0, stepmax = 1, 
                 steptol = 1e-06, hess.eps = 1e-07, verbose = FALSE,iterlim = 100)}
\arguments{
  \item{params}{a vector of initial values.}
  \item{id}{a vector of cluster identifiers.}
  \item{X}{a design matrix, including intercept, for the mean formula.}
  \item{Y}{a binary vector}
  \item{Xgam}{a design matrix for the transition formula.}
  \item{Xsig}{a design matrix for the latent variable formula.}
  \item{Q}{a scalar denoting the number of quadrature points.}
  \item{offset}{an optional offset term.}
  \item{stepmax}{a scalar.}
  \item{steptol}{a scalar.}
  \item{hess.eps}{a scalar.}
  \item{verbose}{an indicator if model output should be printed to the screen during maximization (or minimization of negative log-likelihood). See nlm print.level.}
   \item{iterlim}{a scalar to denote the maximum iteration limit used by nlm. Default value is 100.}
}

\value{ This function returns marginal parameters (beta) and the log-transformed dependence parameters (alpha) along with the associated covariance matricies.}

\references{
Schildcrout, JS and Heagerty, PJ. (2007), Marginalized Models for Moderate to Long Series of Longitudinal Binary Response Data. Biometrics, 63: 322-331.}
\author{ Jonathan Schildcrout }

\seealso{
\code{\link{mm}}
}
