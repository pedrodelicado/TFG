#' @title Plot relev.ghost.var 
#' @name plot.relev.ghost.var
#' 
#' @description \code{\link{plot.relev.ghost.var}} output of the following function \code{\link{relev.ghost.var}}.
#' @param relev.ghost.out out of another function.
#' @param n1 size training set.
#' @param resid.var estimated residual variance in the fitted linear model. It is required for computing de F test values.
#' @param vars contens de indexes de variables that we will represented. It is a number variable to this number is represented. 
#' @param sum.lm.tr summary of the fitted model in the training set when it is a linear model.
#' @param alpha critical value for testing zero relevance, indicated with blue dashed lines in the first two panel.
#' @param ncols.plot number of columns in the plot.
#' 
#' @details The relevance by ghost variables of \code{X1} is much larger than  \code{X2} and \code{X3}. The second graphic in the first row compare the values of the relevance by ghost variables with the corresponding \code{F-statistics} (conveniently transformed). It can be seen that for every explanatory variable both values are almost equal. Blue dashed lines in these two graphics indicate the critical value beyond which an observed relevance can not be considered null, at significance level \code{alpha = 0.01}. The last plot in the upper row shows the eigenvalues of \code{matrix V}, and the plots in the lower row represent the components of each eigenvector.
#' 
#' @seealso \code{\link{relev.ghost.var}} and \code{\link{relevance2cluster}}
#' @rdname plot.relev.ghost.var 
#' @method plot relev.ghost.var
#' @export
#' @export plot.relev.ghost.var

plot.relev.ghost.var <- function(relev.ghost.out, n1, resid.var,
vars=NULL, sum.lm.tr=NULL,
alpha=.01, ncols.plot=3){
  A <- relev.ghost.out$A
  V <- relev.ghost.out$V
  eig.V <- relev.ghost.out$eig.V
  GhostX <- relev.ghost.out$GhostX
  relev.ghost <- relev.ghost.out$relev.ghost
  
  p  <- dim(A)[2]
  
  if (ncols.plot<3){
    ncols.plot<-3 
    warning("The number of plot columns must be at least 3")
  }
  max.plots <- 4*ncols.plot
  if (is.null(vars)){
    vars <- 1:min(max.plots,p)
  }else{
    if (length(vars)>max.plots){
      vars <- vars[1,max.plots]
      warning(
        paste("Only the first", max.plots, "selected variables in 'vars' are used"))
    }
  }
  n.vars <- length(vars)
  nrows.plot <- 1 + n.vars%/%ncols.plot + (n.vars%%ncols.plot>0)
  
  if (!is.null(sum.lm.tr)){
    F.transformed <- resid.var*sum.lm.tr$coefficients[-1,3]^2/n1
  }
  F.critic.transformed <- resid.var*qf(1-alpha,1,n1-p-1)/n1
  
  rel.Gh <- data.frame(relev.ghost=relev.ghost)
  rel.Gh$var.names <- colnames(A)
  
  plot.rel.Gh <- ggplot(rel.Gh) +
    geom_bar(aes(x=reorder(var.names,X=1:length(var.names)), y=relev.ghost), 
      stat="identity", fill="darkgray") +
    ggtitle("Relev. by Ghost variables") +
    geom_hline(aes(yintercept = F.critic.transformed),color="blue",size=1.5,linetype=2)+
    theme(axis.title=element_blank())+
    theme_bw()+
    ylab("Relevance")+
    xlab("Variable name") +
    coord_flip()
  
  plot.rel.Gh.pctg <- ggplot(rel.Gh) +
    geom_bar(aes(x=reorder(var.names,X=1:length(var.names)), 
      y=100*relev.ghost/sum(relev.ghost)), 
      stat="identity", fill="darkgray") +
    coord_flip() +
    ggtitle("Relev. by Ghost variables (% of total relevance)") +
    theme(axis.title=element_blank())
  
  # eigen-structure
  # eig.V <- eigen(V)
  eig.vals.V <- eig.V$values
  eig.vecs.V <- eig.V$vectors
  
  expl.var <- round(100*eig.vals.V/sum(eig.vals.V),2)
  cum.expl.var <- cumsum(expl.var)
  
  # op <-par(mfrow=c(2,2))
  # plot(eig.vals.V, main="Eigenvalues of matrix V",ylab="Eigenvalues", type="b")
  # for (j in (1:p)){
  #   plot(eig.V$vectors[,j],main=paste("Eigenvector",j,", Expl.Var.:",expl.var[j],"%"))
  #   abline(h=0,col=2,lty=2)
  # }
  # par(op)
  
  
  eig.V.df <- as.data.frame(eig.V$vectors)
  eig.V.df$var.names <- colnames(A)
  
  op <-par(mfrow=c(nrows.plot,ncols.plot))
  plot(0,0,type="n",axes=FALSE,xlab="",ylab="")
  
  if (!is.null(sum.lm.tr)){
    plot(F.transformed,relev.ghost,
      xlim=c(0,max(c(F.transformed,relev.ghost))),
      ylim=c(0,max(c(F.transformed,relev.ghost))),
      xlab=expression(paste("F-statistics*",hat(sigma)^2/n[1])), 
      ylab="Relev. by Ghost variables")
    pointLabel(F.transformed,relev.ghost, colnames(A))
    abline(a=0,b=1,col=2)
    abline(v=F.critic.transformed,h=F.critic.transformed,lty=2,col="blue",lwd=2)
  }else{
    plot(0,0,type="n",axes=FALSE,xlab="",ylab="")
  } 
  
  par(xaxp=c(1,p,min(p,5)))
  plot(eig.vals.V, ylim=c(0,max(eig.vals.V)),
    main="Eigenvalues of matrix V",
    ylab="Eigenvalues",type="b")
  abline(h=0,col="red",lty=2)
  
  par(op)
  
  pushViewport(viewport(layout = grid.layout(nrows.plot, ncols.plot))) #package grid
  vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
  print(plot.rel.Gh,vp = vplayout(1,1))
  for (j in vars){
    print(
      ggplot(eig.V.df) +
        #       geom_bar(aes(x=var.names, y=eig.V.df[,j]),
        geom_bar(aes(x=reorder(eig.V.df$var.names,X=1:length(eig.V.df$var.names)), 
          y=eig.V.df[,j]), stat="identity") +
        geom_hline(aes(yintercept=0),color="red",linetype=2,size=1) +
        ylim(min(eig.V.df[,j])-.5,max(eig.V.df[,j])+.5) +
        coord_flip() +
        ggtitle(paste0("Eig.vect.",j,", Expl.Var.: ",expl.var[j],"%")) +
        theme(axis.title=element_blank(),plot.title = element_text(size = 12)),
      vp = vplayout(2+(j-1)%/%ncols.plot, 1+(j-1)%%ncols.plot)
    )
  }
}