## code to prepare `sysdata.rda` dataset goes here

# Train and test matrix and labels for mock data used for
# fitXGBoostModel() in test_xgboost.R 
data_train <- matrix(seq(1:300000), nrow=100000)
data_test <- matrix(c(seq(1:28000), seq(280001:300000)), nrow=16000)
labels_train <- c(rep(1,50000), rep(0,50000))
xgb_model <- fitXGBoostModel(labels_train, data_train, show.cv=TRUE)
# Extract the predictions and results from the list
xgb_predictions = predict(xgb_model, data_test)
xgb.dump(xgb_model, './inst/extdata/xgb_model_splice_junction_correction.txt',
         dump_format='json')
writeLines(as.character(xgb_predictions),
           './inst/extdata/xgb_predictions_splice_junction_correction.txt')


data1 <- data.table(
    txid = c( 1,1, 2, 2),
    equal = rep(FALSE,4),
    eqClassId = c(1,2,3,4),
    eqClassById = list(1,-1,2,-2),
    nobs = c(10, 50, 50,10),
    txlen = c(546,546,2356,2356),
    rcWidth = c(300,540,1800,2300),
    minRC = rep(1,4),
    GENEID = 1
)

data2 <- data.table(
    txid = c( 1,1, 2, 2, 1, 2),
    equal = c(FALSE, TRUE, FALSE, TRUE, FALSE, FALSE),
    eqClassId = c(1,2,3,4,5,5),
    eqClassById = list(1,-1,2,-2,c(1,2),c(1,2)),
    nobs = c(10, 50, 50,10, 500,500),
    txlen = c(546,546,2356,2356, 546,2356),
    rcWidth = c(300,540,1800,2300, 200, 200),
    minRC = rep(1,6),
    GENEID = 2
)

data3 <- data.table(
    txid = c(1,2,3, 2, 2, 1, 2),
    equal = c(TRUE,FALSE, FALSE, TRUE,FALSE, FALSE,FALSE),
    eqClassId = c(1,1,1,2,3,4,4),
    eqClassById = list(c(-1,2,3),c(-1,2,3),c(-1,1,2),-2,2,c(1,2),c(1,2)),
    nobs = c(500, 500, 500,10, 0,50,50),
    txlen = c(546,546,2356,2356,2356, 546,2356),
    rcWidth = c(540,540,540,1800,2300, 200, 200),
    minRC = c(NA,NA,1,1,1,NA,1),
    GENEID = 3
)

data4 <- data.table(
    txid = c(1,2,3, 2, 2, 1, 2),
    equal = c(TRUE, FALSE, FALSE,FALSE,TRUE,FALSE, FALSE),
    eqClassId = c(1,1,1,2,3,4,4),
    eqClassById = list(c(-1,2,3),c(-1,2,3),c(-1,2,3),2,-2, c(1,2),c(1,2)),
    nobs = c(50, 50, 50,100, 500,20,20),
    txlen = c(546,546,2356,2356,2356, 546,2356),
    rcWidth = c(540,540,540,1800,2300, 200, 200),
    minRC = c(NA,NA,1,1,1,NA,1),
    GENEID = 4
)

data5 <- data.table(
    txid = c(1,1,2, 2, 1,2),
    equal = c(FALSE, TRUE, FALSE, TRUE, TRUE, TRUE),
    eqClassId = c(1,2,3,4,5,5),
    eqClassById = list(1,-1,2,-2,c(-1,-2),c(-1,-2)),
    nobs = c(5, 50, 10,60, 200,200),
    txlen = c(546,546,2356,2356, 546,2356),
    rcWidth = c(1700,2200,1800,2300, 2000, 2000),
    minRC = rep(1,6),
    GENEID = 5
)



estOutput_woBC <- lapply(seq_len(5), function(s) {
    print(s)
    est <- bambu.quantDT(readClassDt = get(paste0("data", s)), 
                         emParameters = list(degradationBias = FALSE, 
                                             maxiter = 10000, conv = 10^(-2), minvalue = 10^(-8)))
})

estOutput_wBC <- lapply(seq_len(5), function(s) {
    est <- bambu.quantDT(readClassDt = get(paste0("data", s)))
})


## expected seGeneOutput

se <- readRDS(system.file("extdata", "seOutput_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
seExtended <- readRDS(system.file("extdata", "seOutputExtended_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
seCombined <- readRDS(system.file("extdata", "seOutputCombined_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
seCombinedExtended <- readRDS(system.file("extdata", "seOutputCombinedExtended_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))


seGeneExpected <- transcriptToGeneExpression(se)
seExtendedGeneExpected <- transcriptToGeneExpression(seExtended)
seCombinedGeneExpected <- transcriptToGeneExpression(seCombined)
seCombinedExtendedGeneExpected <- transcriptToGeneExpression(seCombinedExtended)


## prior models to use for scoreReadClass()
#se = readRDS("SGNex_HepG2_directRNA_replicate5_run1_genome.rds")
#defaultModels = trainBambu(se)
xgb.save(defaultModels$transcriptModelME, "./inst/extdata/read_class_ME.model")
xgb.save(defaultModels$transcriptModelSE, "./inst/extdata/read_class_SE.model")
defaultModels$transcriptModelME = NULL
defaultModels$transcriptModelSE = NULL
#saveRDS(defaultModels, "./inst/extdata/defaultModels.rds")
defaultModels = readRDS(system.file("extdata", "defaultModels.rds",
                                    package = "bambu"))
defaultModels$transcriptModelME = xgb.load("./inst/extdata/read_class_ME.model")
defaultModels$transcriptModelSE = xgb.load("./inst/extdata/read_class_SE.model")                                    

# How to get pre trained junction model standardJunctionModels_temp
# added "saveRDS(junctionModel, "./inst/extdata/standardJunctionModels_temp.txt")" to junctionErrorCorrection
# ran Bambu with GNex_HepG2_directRNA_replicate5_run1_genome
standardJunctionModels_temp = readRDS(system.file(
    "extdata", "standardJunctionModels_temp.txt", package = "bambu"))

usethis::use_data(data1, data2, data3, data4, data5,
                  estOutput_woBC,
                  estOutput_wBC,
                  standardJunctionModels_temp,
                  seWithDistExpected,
                  seGeneExpected, seExtendedGeneExpected,
                  seCombinedGeneExpected, seCombinedExtendedGeneExpected,
                  defaultModels,
                  internal = TRUE, overwrite = TRUE
)


## inst data creation
rm(list = ls())
gc()

require(GenomicAlignments) ##readGAlignments
require(AnnotationDbi)#loadDb
require(data.table)#fast large dataset manipulation
require(readxl)


require(ggplot2)
require(RColorBrewer)
require(gridExtra)


cat('Setting working directory')
wkdir <- ''

## get gene List
se <- readRDS("seOutput2020-04-30_updated_wBC.rds")
tx <- rowRanges(se[[1]])
gene <- rowRanges(se[[2]])

geneTx <- as.data.table(mcols(tx))

genecounts <- assays(se[[2]])$counts
txcounts <- assays(se[[1]])$counts

gr <- GRanges(seqnames = "9",
              #ranges = IRanges(1, 1000000),
              ranges = IRanges(1,200000), # for example run in bambu.R only, for demonstration
              strand = "+")

hit <- findOverlaps(gene, gr, ignore.strand = TRUE)


genevec <- names(gene[queryHits(hit)])
txvec <- geneTx[GENEID %in% genevec]$TXNAME

geneList.file <- paste0(wkdir,"/geneList.txt")
write.table(genevec, file = geneList.file, sep = '\t',
            row.names = FALSE, col.names = FALSE)



## get gtf
gtf.file <- "Homo_sapiens.GRCh38.91.gtf"
new_gtf.file <- paste0(wkdir, "/Homo_sapiens.GRCh38.91_chr",as.character(seqnames(gr)),
                       "_",start(gr),"_",end(gr),".gtf")
system2(paste0("grep -f  ",geneList.file," ",gtf.file," > ",new_gtf.file))

## make txdb for chr9
gtf.file <- system.file("extdata", "Homo_sapiens.GRCh38.91_chr9_1_1000000.gtf", package = "bambu")
txdb <- makeTxDbFromGFF(gtf.file, format = "gtf",
                        dataSource="Homo_sapiens.GRCh38.91_chr9_1_1000000.gtf",
                        organism="Homo sapiens",
                        taxonomyId=NA,
                        chrominfo=NULL,
                        miRBaseBuild=NA,
                        metadata=NULL
)
saveDb(txdb, file="./inst/extdata/Homo_sapiens.GRCh38.91.annotations-txdb_chr9_1_1000000.sqlite")




## generate bam file
runname <- "GIS_A549_directRNA_Rep5-Run1"
bamFile <- dir(paste0("/mnt/s3_ontdata.store.genome.sg/Nanopore/03_Mapping/Grch38/minimap2-2.17-directRNA/",runname),
               pattern = ".bam$", full.names = TRUE)
outBam <- paste0(wkdir, "SGNex_A549_directRNA_replicate5_run1.bam")
system2(paste0('samtools-1.8 view -b ',bamFile,' "',
               paste0(as.character(seqnames(gr))),':',start(gr),'-',end(gr), '" > ', outBam))
system2(paste0("samtools-1.8 index ",outBam))

## generate .fa file
fa.file <- paste0(wkdir,"bambu/inst/extdata/Homo_sapiens.GRCh38.dna_sm.primary_assembly_chr9.fa.gz")
outFa <- paste0(wkdir,"Homo_sapiens.GRCh38.dna_sm.primary_assembly_chr9_1_1000000.fa")
system2(paste0("samtools-1.8 faidx ",fa.file," ",paste0(as.character(seqnames(gr))),":",start(gr),"-",end(gr)," > ", outFa))
system2(paste0("zcat ",fa.file," | head -1"))


## generate annotation rds file
txdb <- loadDb(system.file("extdata", "Homo_sapiens.GRCh38.91.annotations-txdb_chr9_1_1000000.sqlite", package = "bambu"))
gr <- prepareAnnotations(txdb)
saveRDS(gr, file = "./inst/extdata/annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", compress = "xz")


## generate readGrgList file
test.bam <- system.file("extdata", "SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.bam", package = "bambu")
readGrgList <- prepareDataFromBam(Rsamtools::BamFile(test.bam))
saveRDS(readGrgList, file = "./inst/extdata/readGrgList_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")


## generate read class files

annotations <- readRDS(system.file("extdata", "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", package = "bambu"))
genomeSequence <- system.file("extdata", "Homo_sapiens.GRCh38.dna_sm.primary_assembly_chr9_1_1000000.fa", package = "bambu")
se <- bambu(reads = test.bam, annotations = annotations, genome = genomeSequence, discovery = FALSE, quant = FALSE)[[1]]
saveRDS(se, file = "./inst/extdata/seReadClassUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")
se <- bambu(reads = test.bam, annotations = annotations, genome = genomeSequence, stranded = TRUE, discovery = FALSE, quant = FALSE)[[1]]
saveRDS(se, file = "./inst/extdata/seReadClassStranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

se <- bambu(reads = test.bam, annotations = annotations, genome = genomeSequence)
saveRDS(se, file = "./inst/extdata/seOutput_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

se <- bambu(reads = test.bam, annotations = annotations, genome = genomeSequence, trackReads = TRUE)
saveRDS(se, file = "./inst/extdata/seOutput_trackReads_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

se <- bambu(reads = test.bam, annotations = annotations, genome = genomeSequence, discovery = FALSE, returnDistTable = TRUE)
saveRDS(se, file = "./inst/extdata/seOutput_distTable_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

se <- bambu(reads = test.bam, annotations = NULL, genome = genomeSequence, NDR = 1)
saveRDS(se, file = "./inst/extdata/seOutput_denovo_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")


##

genomeSequence <- checkInputSequence(genomeSequence)
unlisted_junctions <- unlistIntrons(readGrgList, use.ids = TRUE)
uniqueJunctions <- isore.constructJunctionTables(unlisted_junctions, 
        annotations,genomeSequence, stranded = FALSE, verbose = FALSE)
# create SE object with reconstructed readClasses
seReadClassUnstranded <- isore.constructReadClasses(readGrgList, unlisted_junctions, 
    uniqueJunctions, 
    runName =  "SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000",
    annotations,  stranded = FALSE, verbose = FALSE)
saveRDS(seReadClassUnstranded, file = "./inst/extdata/readClassesUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")
seReadClassStranded <- isore.constructReadClasses(readGrgList = readGrgList,
                                    unlisted_junctions, uniqueJunctions,
                                    runName = "SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000_Stranded",
                                    annotations, stranded = TRUE, verbose = FALSE)
saveRDS(seReadClassStranded, file = "./inst/extdata/readClassesStranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")


## generate seIsoReCombined
seReadClass1 <- readRDS(system.file("extdata", "seReadClassUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
seReadClass2 <- readRDS(system.file("extdata", "seReadClassStranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
#rcFileList <- system.file("extdata", "seReadClassUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu")
bpParameters <- setBiocParallelParameters(reads = seReadClass1, ncore = 1, verbose = FALSE)
seIsoReRef <- isore.combineTranscriptCandidates(readClassList = list(seReadClass1),
                                                stranded = FALSE,min.readCount = 2,
                                                min.txScore.multiExon = 0,
                                                min.txScore.singleExon = 1,
                                                min.readFractionByGene = 0.05,
                                                verbose = FALSE, bpParameters = bpParameters)
rcFileList <- c(system.file("extdata", "seReadClassUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"),
                system.file("extdata", "seReadClassStranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
bpParameters <- setBiocParallelParameters(reads = rcFileList, ncore = 1, verbose = FALSE)
seIsoReCombined <- isore.combineTranscriptCandidates(readClassList = list(seReadClass1,seReadClass2),
                                                     stranded = FALSE,
                                                     min.readCount = 2,
                                                     min.txScore.multiExon = 0,
                                                     min.txScore.singleExon = 1,
                                                     min.readFractionByGene = 0.05,
                                                     verbose = FALSE, bpParameters = bpParameters)

saveRDS(seIsoReRef, file = "./inst/extdata/seIsoReRef_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")
saveRDS(seIsoReCombined, file = "./inst/extdata/seIsoReCombined_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")


## extendedAnnotations
seIsoReCombined <- readRDS(system.file("extdata", "seIsoReCombined_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
gr <- readRDS(system.file("extdata", "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", package = "bambu"))

extendedAnnotations <- isore.extendAnnotations(combinedTranscripts=seIsoReCombined,
                                               annotationGrangesList=gr,
                                               remove.subsetTx = TRUE, min.sampleNumber = 1, NDR = 0.1, 
                                               min.exonDistance = 35, min.exonOverlap = 10,
                                               min.primarySecondaryDist = 5, min.primarySecondaryDistStartEnd = 5, 
                                               prefix='', verbose=FALSE, defaultModels = defaultModels)
saveRDS(extendedAnnotations, file = "./inst/extdata/extendedAnnotationGranges_txdbGrch38_91_chr9_1_1000000.rds", compress = "xz")

## expected output for test isore

seReadClass1 <- readRDS(system.file("extdata", "seReadClassUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
extendedAnnotations <- readRDS(system.file("extdata", "extendedAnnotationGranges_txdbGrch38_91_chr9_1_1000000.rds", package = "bambu"))
gr <- readRDS(system.file("extdata", "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", package = "bambu"))

seWithDistExpected <- isore.estimateDistanceToAnnotations(
    seReadClass = seReadClass1,
    annotationGrangesList = extendedAnnotations,
    min.exonDistance = 35
)
saveRDS(seWithDistExpected, file = "./inst/extdata/distanceToAnnotations_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

set.seed(1234)
seOutputCombined = bambu(reads =  Rsamtools::BamFileList(c(test.bam, test.bam), yieldSize = 1000),  annotations =  gr, genome = genomeSequence, discovery = FALSE)
saveRDS(seOutputCombined, file = "./inst/extdata/seOutputCombined_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

set.seed(1234)
seOutputCombinedExtended = bambu(reads =  Rsamtools::BamFileList(c(test.bam, test.bam), yieldSize = 1000),  annotations =  gr, genome = genomeSequence, discovery = TRUE)
saveRDS(seOutputCombinedExtended, file = "./inst/extdata/seOutputCombinedExtended_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

seReadClass1 <- system.file("extdata", "seReadClassUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu")
gr <- readRDS(system.file("extdata", "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", package = "bambu"))
set.seed(1234)
seOutputExtended <- bambu(reads = seReadClass1, annotations = gr, opt.em = list(degradationBias = FALSE), discovery = TRUE)
saveRDS(seOutputExtended, file = "./inst/extdata/seOutputExtended_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

set.seed(1234)
seOutputCombined2 <- bambu(reads = c(seReadClass1, seReadClass1), annotations = gr, discovery = FALSE)
saveRDS(seOutputCombined2, file = "./inst/extdata/seOutputCombined2_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", compress = "xz")

query <- readRDS(system.file("extdata", "annotateSpliceOverlapByDist_testQuery.rds", package = "bambu"))
subject <- readRDS(system.file("extdata", "annotateSpliceOverlapByDist_testSubject.rds", package = "bambu"))
tab <- compareTranscripts(query, subject)
saveRDS(tab, file = "./inst/extdata/annotateSpliceOverlapsByDist_refoutput.rds", compress = "xz")