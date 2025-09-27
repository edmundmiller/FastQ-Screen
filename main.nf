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

// Help message
if (params.help) {
    // Print help text
    def help_text = """
FastQ Screen Nextflow Pipeline

Usage:
    nextflow run main.nf --input '*.fastq.gz' [options]

Input/output options:
    --input                 Path to FASTQ files (can use glob patterns)
    --outdir                The output directory where results will be saved [default: ./results]

FastQ Screen options:
    --conf                  Path to FastQ Screen configuration file
    --subset                Process only a subset of reads for faster analysis
    --aligner               Alignment tool to use [default: bowtie2]
    --threads               Number of threads to use [default: 4]
    --bisulfite             Enable bisulfite mode
    --paired                Treat input as paired-end reads
    --tag                   Add genome tags to read headers
    --nohits                Output reads that didn't map to any genome
    --illumina1_3           Use Illumina 1.3+ quality encoding
    --filter                Filter reads based on mapping results
    --pass                  Minimum mapping quality threshold
    --inverse               Invert the filter selection
    --top                   Process only the top portion of reads
    --get_genomes           Download default genome databases

Generic options:
    --help                  Display this help message
    --version               Display version and exit
"""
    println help_text
    exit 0
}

// Version message
if (params.version) {
    println "FastQ Screen Nextflow Pipeline version ${workflow.manifest.version ?: '0.16.0'}"
    exit 0
}

// Basic parameter validation
if (!params.input) {
    error "No input files specified. Use --input to specify FASTQ files."
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED MODULES FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQ_SCREEN_SCREEN                  } from './modules/fastq_screen_screen'
include { MAKE_GRAPHS                          } from './modules/make_graphs' 
include { MAKE_HTML_REPORT                     } from './modules/make_html_report'
include { SUBSET_FASTQ                         } from './modules/subset_fastq'

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
    
    if (params.input) {
        if (params.input.endsWith('.tar.gz')) {
            // Handle test dataset or compressed input
            Channel.fromPath(params.input)
                .set { ch_input }
            
            ch_input
                .map { file -> 
                    def extracted = file.toString().replace('.tar.gz', '_extracted')
                    [file, extracted]
                }
                .set { ch_fastq }
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
    } else {
        error "No input files specified. Use --input to specify FASTQ files."
    }

    //
    // Load configuration files and databases
    //
    ch_config = Channel.empty()
    
    if (params.conf) {
        ch_config = Channel.fromPath(params.conf, checkIfExists: true)
    } else if (params.get_genomes) {
        // Handle genome downloading - will be implemented in a separate process
        ch_config = Channel.value('get_genomes')
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