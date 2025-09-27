#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FASTQ-SCREEN NEXTFLOW WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FastQ Screen Nextflow Workflow - A tool for multi-genome mapping and quality control
    
    Github  : https://github.com/edmundmiller/FastQ-Screen
    Website : https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/
    
    Original Perl implementation by:
    - Simon Andrews (The Babraham Institute, UK)
    - Steven Wingett (MRC-LMB, Cambridge, UK) 
    - Felix Krueger (The Babraham Institute, UK)
    - Mark Fiers (Plant & Food Research, NZ)
    - Martin Pollard (Wellcome Sanger Institute, UK)
    
    Nextflow conversion by Edmund Miller
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { validateParameters; paramsSummaryLog } from 'plugin/nf-schema'

// Validate input parameters
validateParameters()

// Print summary of supplied parameters
log.info paramsSummaryLog(workflow)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED MODULES FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQ_SCREEN_SCREEN                  } from './modules/fastq_screen_screen'
include { MAKE_GRAPHS                          } from './modules/make_graphs' 
include { MAKE_HTML_REPORT                     } from './modules/make_html_report'
include { SUBSET_FASTQ                         } from './modules/subset_fastq'
include { EXTRACT_TARBALL                      } from './modules/extract_tarball'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main FastQ Screen analysis pipeline
//
workflow EDMUNDMILLER_FASTQSCREEN {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    ch_fastq = Channel.empty()
    
    // Skip input processing if params.input is null (e.g., when showing help)
    if (params.input == null) {
        error "No input files specified. Use --input to specify FASTQ files."
    }
    
    if (params.input.endsWith('.tar.gz')) {
        // Handle test dataset or compressed input
        Channel.fromPath(params.input)
            .map { file -> [[id: file.baseName.replace('.tar', '')], file] }
            .set { ch_tarball }
        
        EXTRACT_TARBALL(ch_tarball)
        ch_fastq = EXTRACT_TARBALL.out.fastq
        ch_versions = ch_versions.mix(EXTRACT_TARBALL.out.versions)
    } else if (params.input.contains('*') || params.input.contains('?')) {
        // Handle glob patterns
        Channel.fromPath(params.input, checkIfExists: true)
            .map { file -> [[id: file.baseName], file] }
            .set { ch_fastq }
    } else {
        // Handle single file or directory
        Channel.fromPath(params.input, checkIfExists: true)
            .map { file -> [[id: file.baseName], file] }
            .set { ch_fastq }
    }

    //
    // Load configuration files and databases
    //
    ch_config = Channel.empty()
    
    if (params.conf) {
        ch_config = Channel.fromPath(params.conf, checkIfExists: true)
    } else if (params.get_genomes) {
        // For testing, use the test config if available, otherwise use default config
        def test_config = "${projectDir}/fastq_screen_test.conf"
        if (file(test_config).exists()) {
            ch_config = Channel.fromPath(test_config)
        } else {
            def default_config = "${projectDir}/fastq_screen.conf.example"
            if (file(default_config).exists()) {
                ch_config = Channel.fromPath(default_config)
            } else {
                error "No configuration file found. Use --conf to specify a config file."
            }
        }
    } else {
        // Look for default config
        def default_config = "${projectDir}/fastq_screen.conf.example"
        if (file(default_config).exists()) {
            ch_config = Channel.fromPath(default_config)
        } else {
            error "No configuration file found. Use --conf to specify a config file or --get_genomes to download default genomes."
        }
    }

    //
    // MODULE: Subset FASTQ files if requested
    //
    if (params.subset || params.top) {
        SUBSET_FASTQ (
            ch_fastq,
            params.subset ?: 0,
            params.top ?: ''
        )
        ch_fastq = SUBSET_FASTQ.out.fastq
        ch_versions = ch_versions.mix(SUBSET_FASTQ.out.versions)
    }

    //
    // MODULE: Run FastQ Screen analysis
    //
    FASTQ_SCREEN_SCREEN (
        ch_fastq,
        ch_config,
        params.aligner ?: 'bowtie2',
        params.threads ?: 4,
        params.bisulfite ?: false,
        params.tag ?: false,
        params.nohits ?: false,
        params.illumina1_3 ?: false,
        params.paired ?: false,
        params.bowtie_opts ?: '',
        params.bowtie2_opts ?: '',
        params.bismark_opts ?: '',
        params.bwa_opts ?: '',
        params.minimap2_opts ?: '',
        params.filter ?: '',
        params.pass ?: 0,
        params.inverse ?: false
    )
    ch_versions = ch_versions.mix(FASTQ_SCREEN_SCREEN.out.versions)

    //
    // MODULE: Generate graphs if possible
    //
    MAKE_GRAPHS (
        FASTQ_SCREEN_SCREEN.out.results,
        params.bisulfite ?: false
    )
    ch_versions = ch_versions.mix(MAKE_GRAPHS.out.versions)

    //
    // MODULE: Generate HTML report
    //
    MAKE_HTML_REPORT (
        FASTQ_SCREEN_SCREEN.out.results,
        MAKE_GRAPHS.out.png.ifEmpty([])
    )
    ch_versions = ch_versions.mix(MAKE_HTML_REPORT.out.versions)

    //
    // MODULE: Filter reads if requested - handled by main fastq-screen process
    //

    emit:
    results      = FASTQ_SCREEN_SCREEN.out.results
    html         = MAKE_HTML_REPORT.out.html
    png          = MAKE_GRAPHS.out.png
    filtered     = FASTQ_SCREEN_SCREEN.out.filtered
    versions     = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN ALL WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Execute a single named workflow for the pipeline
// See: https://github.com/nf-core/rnaseq/issues/619
//
workflow {
    EDMUNDMILLER_FASTQSCREEN ()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/