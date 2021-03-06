#' plots data stored in bed file format
#' 
#'
#' @param signal signal track data to be plotted (in bedgraph format)
#' @param chrom chromosome of region to be plotted
#' @param chromstart start position
#' @param chromend end position
#' @param range y-range to plpt ( c(min,max) )
#' @param color color of signal track  
#' @param lwd color of line outlining signal track.  (only valid if linecol is not NA)
#' @param linecolor color of line outlining signal track.  use NA for no outline
#' @param addscale TRUE/FALSE whether to add a y-axis
#' @param overlay TRUE / FALSE whether this data should be plotted on top of an existing plot
#' @param rescaleoverlay TRUE/FALSE whether the new plot shold be rescaled based on the maximum value to match the existing plot (only valid when overlay is set to 'TRUE')   
#' @param transparency Value between 0 and 1 indication the degree of transparency of the plot
#' @param flip TRUE/FALSE whether the plot should be flipped over the x-axis
#' @param xaxt A character which specifies the x axis type.  See \code{\link{par}}
#' @param yaxt A character which specifies the y axis type.  See \code{\link{par}}
#' @param xlab Label for the x-axis
#' @param ylab Label for the y-axis
#' @param xaxs Must be set to 'i' for appropriate integration into Sushi plots.  See \code{\link{par}}
#' @param yaxs Must be set to 'i' for appropriate integration into Sushi plots.  See \code{\link{par}}
#' plottype
#' @param bty A character string which determined the type of box which is drawn about plots.  See \code{\link{par}}
#' @param ymax fraction of max y value to set as height of plot.
#' @param binSize the length of each bin in bp
#' @param binCap TRUE/FALSE whether the function will limit the number of bins to 8,000
#' @param ... values to be passed to \code{\link{plot}}
#' @export
#' @examples
#'
#' data(Sushi_ChIPSeq_CTCF.bedgraph)
#' data(Sushi_DNaseI.bedgraph)
#'
#' chrom            = "chr11"
#' chromstart       = 1955000
#' chromend         = 1965000
#' 
#' plotBedgraph(Sushi_ChIPSeq_CTCF.bedgraph,chrom,chromstart,chromend,transparency=.50,flip=FALSE,color="blue",linecol="blue")
#' plotBedgraph(Sushi_DNaseI.bedgraph,chrom,chromstart,chromend,transparency=.50,flip=FALSE,color="#E5001B",linecol="#E5001B",overlay=TRUE,rescaleoverlay=TRUE)
#' 
#' transparency = 0.5
#' col1 = col2rgb("blue")
#' finalcolor1 = rgb(col1[1],col1[2],col1[3],alpha=transparency * 255,maxColorValue = 255)
#' col2 = col2rgb("#E5001B")
#' finalcolor2 = rgb(col2[1],col2[2],col2[3],alpha=transparency * 255,maxColorValue = 255)
#' 
#' legend("topright",inset=0.025,legend=c("DnaseI","ChIP-seq (CTCF)"),fill=c(finalcolor1,finalcolor2),border=c("blue","#E5001B"),text.font=2,cex=0.75)
plotBedgraph <-
  function(signal,chrom,chromstart,chromend,range=NULL,color=SushiColors(2)(2)[1],
           lwd=1,linecolor=NA,addscale=FALSE,overlay=FALSE,rescaleoverlay=FALSE,transparency=1.0,
           flip=FALSE, xaxt='none',yaxt='none',xlab="",ylab="",xaxs="i",yaxs="i",bty='n',ymax=1.04, binSize=NA, binCap=TRUE,...)
  {
    if (overlay == TRUE)
    {
      colorbycol = NULL
    }
    
    if(is.na(linecolor ) == TRUE)
    {
      linecolor = color
    }
    
    if(is.na(binSize) == TRUE)
    {
      binSize = (chromend - chromstart)/2000
    }
    
    # ensure that the chromosome is a character
    signal[,1] = as.character(signal[,1])
    
    # filter for desired region
    signaltrack = signal[which(signal[,1] == chrom & ((signal[,2] > chromstart & signal[,2] < chromend) |  (signal[,3] > chromstart & signal[,3] < chromend))),(2:4)]
    
    # remove any duplicate rows
    signaltrack = signaltrack[!duplicated(signaltrack),]
    
    # exit if overlay is TRUE and there isn't enough data
    if (overlay ==TRUE && nrow(signaltrack) < 2)
    {
      return ("not enough data within range to plot")
    }
    
    # exit if overlay is FALSE and there isn't enough data
    if (nrow(signaltrack) < 2)
    {
      if (is.null(range) == TRUE)
      {
        range = c(0,1)
      }
      
      # make blank plot
      plot(0,0,xlim=c(chromstart,chromend),type='n',ylim=range,xaxt=xaxt,yaxt=yaxt,ylab=ylab,xaxs=xaxs,yaxs=yaxs,bty=bty,xlab=xlab,...) 
      return ("not enough data within range to plot")
    }
    
    binNum = (chromend - chromstart)/binSize
    
    # scale back binNum and print warning if binNum is greater than 8000
    if(binNum > 8000 && binCap == TRUE){
      binNum = 8000
      binSize = (chromend - chromstart)/binNum
      warning(paste0("Too many bins: adjusting to 8000 bins of size ", binSize, ". To override try binCap = FALSE."))
    }
    
    # scale bin size to 1 if binNum is larger than span
    if (binNum > (chromend - chromstart)){
      binNum = (chromend - chromstart)
      binSize = 1
      warning(paste0("Number of bins larger than plot length: adjusting to ", binNum, " bins of size 1."))
    } 
    
    # if (nrow(signaltrack) %% binSize != 0) # remove the extra rows that won't fit evenly into a bin
    # {
    #   signaltrack = signaltrack[1:(nrow(signaltrack)-(nrow(signaltrack) %% binSize)),]
    # }
    
    bin.dataframe <- data.frame(seq(chromstart, chromend-binSize, binSize), seq(chromstart+binSize, chromend, binSize), rep(0, times=binNum))
    
    # add column names
    colnames(bin.dataframe) = c("V1", "V2", "V3")
    
    # find the max signal values for each bin
    bin.signal <- function(line){ 
      signal=signaltrack
      line = as.integer(line)
      list=c(0)
      list = append(list, signal[,3][which((signal[,1] >= line[1] & signal[,1] < line[2]) |
                                             signal[,2] > line[1] & signal[,2] <= line[2] |
                                             signal[,1] < line[1] & signal[,2] > line[2])])
      return(max(list))
    }
    bin.dataframe[,3] = apply(bin.dataframe, 1, bin.signal) 
    
    # use binned data as signal track
    signaltrack = bin.dataframe
    
    # make linking regions if neccesary
    linkingregions = cbind(signaltrack[1:(nrow(signaltrack)-1),2], signaltrack[2:nrow(signaltrack),1])
    linkingregions = matrix(linkingregions[which(linkingregions[,1] != linkingregions[,2]),],ncol=2)
    
    if (nrow(linkingregions) > 0)
    {
      linkingregions = cbind(linkingregions,0)
      
      # make col names the same
      names(linkingregions)[(1:3)] = c("V1","V2","V3")
      
      # add linking regions to signaltrack
      signaltrack = rbind(signaltrack,linkingregions)
    }
    
    # sort data
    signaltrack = signaltrack[order(signaltrack[,1]),]
    
    # convert two columns to one
    signaltrack = cbind(as.vector(t(signaltrack[,c(1,2)])),as.vector(t(signaltrack[,c(3,3)])))
    
    # add slighltly negative vaue to both ends to ensure proper polygon plotting
    signaltrack = rbind(c(min(signaltrack[,1]),-.00001),signaltrack)
    signaltrack = rbind(signaltrack, c(max(signaltrack[,1]),-.00001))
    
    if (flip == TRUE)
    {
      signaltrack[,2] = signaltrack[,2]*-1
    }
    
    # determine the y-limits
    if (is.null(range) == TRUE)
    {
      range = c(0,ymax*max(signaltrack[,2]))
      if (flip == TRUE)
      {
        range = c(ymax*min(signaltrack[,2]),0)
      }
    }
    
    if (overlay == FALSE)
    {
      # make blank plot
      plot(signaltrack,xlim=c(chromstart,chromend),type='n',ylim=range,xaxt=xaxt,yaxt=yaxt,ylab=ylab,xaxs=xaxs,yaxs=yaxs,bty=bty,xlab=xlab) 
    }
    
    # rescale the overlay plot for comparative purposes
    if (rescaleoverlay == TRUE)
    {
      if (flip == FALSE)
      {
        signaltrack[,2] =   par('usr')[4] * signaltrack[,2] / max(abs(signaltrack[,2]) )
      }
      if (flip == TRUE)
      {
        
        signaltrack[,2] =   abs(par('usr')[3]) * signaltrack[,2] / max(abs(signaltrack[,2]) )
      }
    }
    
    # set the transparency
    rgbcol = col2rgb(color)
    finalcolor = rgb(rgbcol[1],rgbcol[2],rgbcol[3],alpha=transparency * 255,maxColorValue = 255)
    
    # plot the signal track
    polygon(signaltrack,col=finalcolor,border=linecolor,lwd=lwd)
    
    # add scale to upper right corner
    if (addscale == TRUE)
    {
      mtext(paste(range[1],range[2],sep="-"),side=3,font=1,adj=1.00,line=-1)
    }
  }