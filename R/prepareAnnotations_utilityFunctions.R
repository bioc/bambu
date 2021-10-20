#' Prepare annotation granges object from GTF file
#' @title Prepare annotation granges object from GTF file into a 
#' GRangesList object
#' @param file a GTF file
#' @return A \code{\link{GRangesList}} object
#' @details Unlike \code{\link{readFromGTF}}, this function finds out the
#' equivalence classes between the transcripts,
#' with \code{\link{mcols}} data having three columns:
#' \itemize{
#'     \item TXNAME specifying prefix for new gene Ids (genePrefix.number),
#'     defaults to empty
#'     \item GENEID indicating whether filter to remove read classes
#'     which are a subset of known transcripts(), defaults to TRUE
#'     \item eqClass specifying minimun read count to consider a read class
#'     valid in a sample, defaults to 2
#'   }
#' @importFrom GenomicRanges makeGRangesListFromDataFrame 
#' @noRd
prepareAnnotationsFromGTF <- function(file) {
    if (missing(file)) {
        stop("A GTF file is required.")
    } else {
        data <- utils::read.delim(file, header = FALSE, comment.char = "#")
        colnames(data) <- c("seqname", "source", "type", "start", "end",
            "score", "strand", "frame", "attribute")
        data <- data[data$type == "exon", ]
        data$strand[data$strand == "."] <- "*"
        data$GENEID <- gsub("gene_id (.*?);.*", "\\1", data$attribute)
        data$TXNAME <- gsub(".*transcript_id (.*?);.*", "\\1", data$attribute)
        geneData <- unique(data[, c("TXNAME", "GENEID")])
        grlist <- makeGRangesListFromDataFrame(
        data[, c("seqname", "start", "end", "strand", "TXNAME")],
            split.field = "TXNAME", keep.extra.columns = TRUE)
        grlist <- grlist[IRanges::order(start(grlist))]
        unlistedExons <- unlist(grlist, use.names = FALSE)
        partitioning <- PartitioningByEnd(cumsum(elementNROWS(grlist)),
            names = NULL)
        txIdForReorder <- togroup(PartitioningByWidth(grlist))
        exon_rank <- lapply(elementNROWS(grlist), seq, from = 1)
        exon_rank[which(unlist(unique(strand(grlist))) == "-")] <- lapply(
            exon_rank[which(unlist(unique(strand(grlist))) == "-")], rev
            ) # * assumes positive for exon ranking
        names(exon_rank) <- NULL
        unlistedExons$exon_rank <- unlist(exon_rank)
        unlistedExons <- unlistedExons[order(txIdForReorder,
            unlistedExons$exon_rank)]
        # exonsByTx is always sorted by exon rank, not by strand,
        # make sure that this is the case here
        unlistedExons$exon_endRank <- unlist(lapply(elementNROWS(grlist),
            seq, to = 1), use.names = FALSE)
        unlistedExons <- unlistedExons[order(txIdForReorder,
            start(unlistedExons))]
        mcols(unlistedExons) <- mcols(unlistedExons)[, c("exon_rank",
            "exon_endRank")]
        grlist <- relist(unlistedExons, partitioning)
        # sort the grlist by start position, ranked by exon number
        minEqClasses <- getMinimumEqClassByTx(grlist)
        mcols(grlist) <- DataFrame(geneData[(match(names(grlist),
            geneData$TXNAME)), ])
        mcols(grlist)$eqClass <- minEqClasses$eqClass[match(
            names(grlist), minEqClasses$queryTxId)]
    }
    return(grlist)
}


#' Get minimum equivalent class by Transcript
#' @param exonsByTranscripts exonsByTranscripts
#' @importFrom dplyr tibble
#' @noRd
getMinimumEqClassByTx <- function(exonsByTranscripts) {
    exByTxAnnotated_singleBpStartEnd <-
        cutStartEndFromGrangesList(exonsByTranscripts)
    # estimate overlap only based on junctions
    spliceOverlaps <- findSpliceOverlapsQuick(
        exByTxAnnotated_singleBpStartEnd,
        exByTxAnnotated_singleBpStartEnd
        )
    ## identify transcripts compatible with other (subsets by splice sites)
    spliceOverlaps <- spliceOverlaps[mcols(spliceOverlaps)$compatible == TRUE, ]
    ## select splicing compatible transcript matches
    
    queryTxId <-
        names(exByTxAnnotated_singleBpStartEnd)[queryHits(spliceOverlaps)]
    subjectTxId <-
        names(exByTxAnnotated_singleBpStartEnd)[subjectHits(spliceOverlaps)]
    subjectTxId <- subjectTxId[order(queryTxId, subjectTxId)]
    queryTxId <- sort(queryTxId)
    eqClass <- unstrsplit(splitAsList(subjectTxId, queryTxId), sep = ".")

    return(tibble(queryTxId = names(eqClass), eqClass = unname(eqClass)))
}
