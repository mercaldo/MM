MMLongit <- function(params, id, X, Y, Xgam, Xsig, Q, offset=rep(0, length(Y)),
                     stepmax=1, steptol=1e-6,hess.eps=1e-7, verbose=FALSE,iterlim){
  tmp <- get.GH(Q)
  W   <- tmp$w
  Z   <- tmp$z
  
  ## In the case where Xgam or Xsig are vectors, this converts them to matrices, so that matrix multiplication is possible in C.
  Xgam <- cbind(Xgam, NULL)
  Xsig <- cbind(Xsig, NULL)
  
  if ( length(params) != ncol(X) + ncol(Xgam) + ncol(Xsig) ) { stop("Parameter length incongruous with X, Xgam, and Xsig")}
  paramlengths <- c(ncol(X), ncol(Xgam), ncol(Xsig))
  
  ## Lagged response
  Ylag <- rep(0, length(Y))
  for(i in 2:length(Y)) { if(id[i]==id[i-1]) Ylag[i]<-Y[i-1] }

  if (is.matrix(Xgam)){ 
    Xgam.col <- ncol(Xgam)
  } else{Xgam.col <- 1}
  if (is.matrix(Xsig)){ 
    Xsig.col <- ncol(Xsig)
  } else{Xsig.col <- 1}

  id.tmp     <- split(id, id)
  X.tmp      <- split(X,id)
  Y.tmp      <- split(Y,id)
  Ylag.tmp   <- split(Ylag,id)
  Xgam.tmp   <- split(Xgam,id)
  Xsig.tmp   <- split(Xsig,id)
  offset.tmp <- split(offset,id)
  
  subjectData <- vector('list', length=length(unique(id)))
  subjectData <- list()
  uid <- as.character(unique(id))
  for(j in seq(along=uid)){
    i <- uid[j]
    subjectData[[j]] <- list(id=as.character(unique(id.tmp[[i]])), 
                             X=matrix(X.tmp[[i]], ncol=ncol(X)), 
                             Y=as.double(Y.tmp[[i]]),
                             Ylag=as.double(Ylag.tmp[[i]]),
                             Xgam=matrix(Xgam.tmp[[i]], ncol=Xgam.col),
                             Xsig=matrix(Xsig.tmp[[i]], ncol=Xsig.col),
                             Offset=as.double(offset.tmp[[i]]))
  }
  names(subjectData) <- uid

  ## Fit the data using R's nlm() minimizer function
  fit   <- nlm(LogLScoreCalc, params, subjectData=subjectData, ParamLengths=paramlengths, 
               Q=Q, W=W, Z=Z, print.level=verbose*2, stepmax=stepmax, steptol=steptol, hessian=FALSE, iterlim=iterlim)

  LogLikeSubj.tmp <- LogLScoreCalc( params=fit$estimate, subjectData=subjectData, 
                                           Q=Q, W=W, Z=Z, ParamLengths=paramlengths )
  LogLikeSubj <- attr(LogLikeSubj.tmp,"LogLikeSubj")
  
  ## Calculate Hessian / Model Based Covariance
  NumSubjs  <- length(subjectData)
  NumEsts   <- length(fit$estimate)
  ObsInfo_i <- vector('list',NumSubjs) 
  Grad_j    <- vector('list', NumEsts)

  eps.mtx       <- diag(rep(hess.eps, NumEsts))
  grad.at.max   <- fit$gradient
  ObsInfo       <- matrix(NA, NumEsts, NumEsts) 
  grad_mat      <- matrix(NA, NumEsts, NumEsts)
  
  for (j in 1:length(fit$estimate)){
    temp        <- LogLScoreCalc( params=(fit$estimate+eps.mtx[j,]), subjectData=subjectData, 
                                  Q=Q, W=W, Z=Z, ParamLengths=paramlengths )
      ObsInfo[j,]  <- (attr(temp,"gradient") - grad.at.max)/hess.eps
      grad_mat[j,] <- attr(temp,"gradient") 
      
      grad <- ddtheta_loglikei <- -matrix( attr(temp, "ddtheta_loglikei"), ncol=length(params), byrow=TRUE)
      sig_index <- (paramlengths[1] + paramlengths[2] + 1):(paramlengths[1] + paramlengths[2] + paramlengths[3])
      sigma_tmp <- exp(fit$estimate[sig_index]+hess.eps)
      for(k in seq(length(sig_index)) ) grad[,sig_index[k]] <- sigma_tmp[k]*ddtheta_loglikei[,sig_index[k]]
      Grad_j[[j]] <- grad
      # do.call(rbind, lapply(Grad_j, colSums)) = grad_mat
      # ObsInfo= (grad_mat-matrix(rep(grad.at.max, NumEsts), ncol=NumEsts,byrow=TRUE))/hess.eps
    }
  
  grad.at.max.i <- -matrix( attr(LogLikeSubj.tmp, "ddtheta_loglikei"), ncol=sum(paramlengths), byrow=TRUE)
  sig_index <- (paramlengths[1] + paramlengths[2] + 1):(paramlengths[1] + paramlengths[2] + paramlengths[3])
  sigma_tmp <- exp(fit$estimate[sig_index])
  for(k in seq(length(sig_index)) ) grad.at.max.i[,sig_index[k]] <- sigma_tmp[k]*grad.at.max.i[,sig_index[k]]
  
  Grad_tmp <- do.call(cbind, Grad_j)
  Grad_i <- vector('list',NumSubjs) 
  for (j in seq(NumSubjs)) {
    Grad_i[[j]] <-matrix(Grad_tmp[j,],ncol=NumEsts,byrow=TRUE)
    ObsInfo_i[[j]] <- (Grad_i[[j]]-matrix(rep(grad.at.max.i[j,], NumEsts), ncol=NumEsts,byrow=TRUE))/(hess.eps)
  }

  ## This step removes the rows and columns of the observed information matrix that are all zeros
  ## For example, in a random intercept model, this will be the transition component row/column and 
  ## in a transition model, this will be the variance component row/column
  RowNotAll0s <- apply(ObsInfo, 1, function(x) !all(x == 0))
  ObsInfo     <- ObsInfo[RowNotAll0s, RowNotAll0s]
  InvObsInfo  <- solve(ObsInfo)
  
  ObsInfo_i <- lapply(ObsInfo_i, function(ZZ) {
    ZZ[RowNotAll0s, RowNotAll0s]
  })

  ## Empirical Covariance 
  Cheese  <- LogLScoreCalc( params=fit$estimate, subjectData=subjectData, Q=Q, W=W, Z=Z,
                            ParamLengths=paramlengths, EmpiricalCheeseCalc=TRUE)
  
  ## This step removes the rows and columns of the cheese matrix that are all zeros
  ## For example, in a random intercept model, this will be the transition component row/column and 
  ## in a transition model, this will be the variance component row/column
  Cheese <- Cheese[RowNotAll0s, RowNotAll0s]
  EmpiricalCov <- InvObsInfo%*%Cheese%*%InvObsInfo
  
  LenBetaM     <- paramlengths[1]
  fit$estimate <- fit$estimate[RowNotAll0s]
  grad.at.max  <- grad.at.max[RowNotAll0s]
  LenAllParams <- length(fit$estimate)
  
  beta          <- fit$estimate[ 1         : LenBetaM ]
  alpha         <- fit$estimate[ (LenBetaM+1) : LenAllParams ]
  gradient      <- -1*grad.at.max
  varbeta       <- diag(InvObsInfo)[ 1         : LenBetaM ]
  varalpha      <- diag(InvObsInfo)[ (LenBetaM+1) : LenAllParams ]
  cov.model     <- InvObsInfo
  cov.empirical <- EmpiricalCov
  Cheese        <- Cheese
  code          <- fit$code
  n.iter        <- fit$iterations
  
  out<-list(beta=beta, alpha=alpha, logL=-fit$minimum,  gradient=-1*gradient,
            varbeta=varbeta,varalpha=varalpha,modelcov=cov.model, empiricalcov=cov.empirical,
            Cheese=Cheese, code=code, Q=Q, niter=n.iter, LogLikeSubj=LogLikeSubj, ObsInfoSubj=ObsInfo_i)
  class(out)="MMLongit"
  out
}
