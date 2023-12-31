context("Isoform quantification")

# bambu.quantDT
test_that("generic function of isoform quantification of data.table is list of 2", {
    # test case
    #   1: simplest case with no overlap
    #   2: simple overlapping scenario (not subset)
    #   3: subset scenario 1 with subset transcript being highly expressed 
    #   4: subset scenario 2 with long transcript being highly expressed
    #   5: highly similar transcripts scenario 
    
    lapply(1:5, function(s) {
        est <- bambu.quantDT(readClassDt = get(paste0("data", s)),
                             emParameters = list(degradationBias = FALSE, maxiter = 10000, 
                                                 conv = 10^(-2), minvalue = 10^(-8)))
        expect_type(est, "list")
        expect_equal(est, estOutput_woBC[[s]])
    })
    
    ## with bias correction
    lapply(1:5, function(s) {
        est <- bambu.quantDT(readClassDt = get(paste0("data", s)),
                             emParameters = list(degradationBias = TRUE, maxiter = 10000,
                                                 conv = 10^(-2), minvalue = 10^(-8)))
        expect_type(est, "list")
        expect_equal(est, estOutput_wBC[[s]])
    })
})




test_that("bambu (isoform quantification of bam file) produces expected output", {
    test.bam <- system.file("extdata", 
                            "SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.bam",
                            package = "bambu")
    fa.file <- system.file("extdata", 
                           "Homo_sapiens.GRCh38.dna_sm.primary_assembly_chr9_1_1000000.fa", 
                           package = "bambu")
    
    annotations <- readRDS(system.file("extdata", "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", package = "bambu"))
    
    gr <- readRDS(system.file("extdata", 
                              "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", 
                              package = "bambu"))
    
    
    seExpected <- readRDS(system.file("extdata", 
                                      "seOutput_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", 
                                      package = "bambu"))
    seCombinedExpected <- readRDS(system.file("extdata", 
                                              "seOutputCombined_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds",
                                              package = "bambu"))
    
    # test case 1: bambu with single bam file, only using annotations (default option)
    set.seed(1234)
    se <- bambu(reads = test.bam, annotations = annotations, genome = fa.file)
    expect_s4_class(se, "SummarizedExperiment")
    expect_equal(assays(se), assays(seExpected))
    
    # test case 2: bambu with multiple bam file, only using annotations (default option), yieldSize lower than read count
    set.seed(1234)
    seCombined <- bambu(reads = Rsamtools::BamFileList(c(test.bam, test.bam), 
                                                       yieldSize = 1000), annotations = gr, genome = fa.file, discovery = FALSE)
    expect_s4_class(seCombined, "SummarizedExperiment")
    expect_equal(seCombined, seCombinedExpected)
})



test_that("bambu (isoform quantification of bam file and save readClassFiles) produces expected output", {
    ## ToDo: update data sets for comparison
    
    test.bam <- system.file("extdata", 
                            "SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.bam", 
                            package = "bambu")
    fa.file <- system.file("extdata", 
                           "Homo_sapiens.GRCh38.dna_sm.primary_assembly_chr9_1_1000000.fa", 
                           package = "bambu")
    
    gr <- readRDS(system.file("extdata", 
                              "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", 
                              package = "bambu"))
    rcOutDir <- tempdir()
    
    
    seExpected <- readRDS(system.file("extdata", 
                                      "seOutput_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", 
                                      package = "bambu"))
    seCombinedExtendedExpected <- readRDS(system.file("extdata", 
                                                      "seOutputCombinedExtended_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", 
                                                      package = "bambu"))
    
    # test case 1: bambu with single bam file, only using annotations (default option)
    set.seed(1234)
    se <- bambu(reads = test.bam, annotations = gr, genome = fa.file)
    expect_s4_class(se, "SummarizedExperiment")
    expect_equal(se, seExpected)
    
    
    # test case 2: bambu with multiple bam file, extending annotations, yieldSize lower than read count
    set.seed(1234)
    seCombinedExtended <- 
        bambu(reads = Rsamtools::BamFileList(c(test.bam, test.bam), 
                                             yieldSize = 1000), annotations = gr, genome = fa.file, discovery = TRUE)
    expect_s4_class(seCombinedExtended, "SummarizedExperiment")
    expect_equal(seCombinedExtended, seCombinedExtendedExpected)
})




test_that("bambu (isoform quantification of saved readClassFiles) produces expected output", {
    ## ToDo: update data sets for comparison
    seReadClass1 <- system.file("extdata", "seReadClassUnstranded_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu")
    gr <- readRDS(system.file("extdata", "annotationGranges_txdbGrch38_91_chr9_1_1000000.rds", package = "bambu"))
    
    
    seExtendedExpected <- readRDS(system.file("extdata", "seOutputExtended_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
    seCombinedExpected <- readRDS(system.file("extdata", "seOutputCombined2_SGNex_A549_directRNA_replicate5_run1_chr9_1_1000000.rds", package = "bambu"))
    
    
    # test case 1: bambu with single bam file, only using annotations (default option)
    set.seed(1234)
    seExtended <- bambu(reads = seReadClass1, annotations = gr, 
                        opt.em = list(degradationBias = FALSE), discovery = TRUE)
    expect_s4_class(seExtended, "SummarizedExperiment")
    expect_equal(seExtended, seExtendedExpected)
    
    
    # test case 2: bambu with multiple bam file, only using annotations (default option), yieldSize lower than read count
    set.seed(1234)
    seCombined <- bambu(reads = c(seReadClass1, seReadClass1), annotations = gr, discovery = FALSE)
    expect_s4_class(seCombined, "SummarizedExperiment")
    expect_equal(seCombined, seCombinedExpected)
})