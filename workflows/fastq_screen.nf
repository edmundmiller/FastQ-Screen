/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: FastQ Screen
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// No specific parameter validation imports needed for this simplified version

//
// MODULE: Installed directly from modules
//
include { FASTQ_SCREEN_SCREEN                  } from '../modules/fastq_screen_screen'
include { MAKE_GRAPHS                          } from '../modules/make_graphs' 
include { MAKE_HTML_REPORT                     } from '../modules/make_html_report'
include { SUBSET_FASTQ                         } from '../modules/subset_fastq'
include { FILTER_READS                         } from '../modules/filter_reads'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow FASTQ_SCREEN {

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
        params.minimap2_opts ?: ''
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
    // MODULE: Filter reads if requested
    //
    if (params.filter) {
        FILTER_READS (
            FASTQ_SCREEN_SCREEN.out.tagged.ifEmpty([]),
            params.filter,
            params.pass ?: 1,
            params.inverse ?: false
        )
        ch_versions = ch_versions.mix(FILTER_READS.out.versions)
    }

    emit:
    results      = FASTQ_SCREEN_SCREEN.out.results
    html         = MAKE_HTML_REPORT.out.html
    png          = MAKE_GRAPHS.out.png
    filtered     = params.filter ? FILTER_READS.out.filtered : Channel.empty()
    versions     = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/